import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/settings_row.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/layout_insets.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;
  String _lastBackupDate = 'Never';
  String _lastBackupSize = '';
  String _lastAutoBackupDate = 'Never';
  bool _isLastBackupEncrypted = false;

  bool _encryptBackup = false;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final service = ref.read(backupServiceProvider);
    final key = service.metadataKey;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lastBackupDate = prefs.getString(key('last_backup_date')) ?? 'Never';
      _lastBackupSize = prefs.getString(key('last_backup_size')) ?? '';
      _lastAutoBackupDate =
          prefs.getString(key('last_auto_backup_display')) ?? 'Never';
      _isLastBackupEncrypted =
          prefs.getBool(key('last_backup_encrypted')) ?? false;
    });
  }

  Future<void> _saveMetadata(int sizeBytes, bool encrypted) async {
    final service = ref.read(backupServiceProvider);
    final scope = service.accountScope;
    String key(String name) => '${name}_$scope';
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('MMM dd, yyyy · HH:mm').format(DateTime.now());

    final sizeKb = sizeBytes / 1024;
    String sizeStr;
    if (sizeKb > 1024) {
      sizeStr = '${(sizeKb / 1024).toStringAsFixed(1)} MB';
    } else {
      sizeStr = '${sizeKb.toStringAsFixed(0)} KB';
    }

    await prefs.setString(key('last_backup_date'), dateStr);
    await prefs.setString(key('last_backup_size'), sizeStr);
    await prefs.setBool(key('last_backup_encrypted'), encrypted);

    if (!mounted || service.accountScope != scope) return;
    setState(() {
      _lastBackupDate = dateStr;
      _lastBackupSize = sizeStr;
      _isLastBackupEncrypted = encrypted;
    });
  }

  Future<void> _handleCreateBackup() async {
    if (_encryptBackup && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a password for encryption'),
          backgroundColor: context.colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);

      final zipPath = await backupService.createBackup(
        password: _encryptBackup ? _passwordController.text : null,
      );

      if (zipPath != null && mounted) {
        final file = File(zipPath);
        await _saveMetadata(await file.length(), _encryptBackup);

        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(zipPath)], text: 'Sthira Backup');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create backup'),
              backgroundColor: context.colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving backup: $e'),
            backgroundColor: context.colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _promptForPassword() async {
    final TextEditingController pc = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Encrypted Backup',
          style: context.text.body.copyWith(color: context.colors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This backup is encrypted. Please enter the password to unlock it.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pc,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, pc.text),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  /// Android SAF often returns [PlatformFile.path] == null. Prefer path when
  /// present; otherwise write [PlatformFile.bytes] to a temp file.
  Future<String?> _resolvePickedZipPath(PlatformFile file) async {
    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return path;
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not read the selected file. Try again or pick from Downloads.',
            ),
            backgroundColor: context.colors.red,
          ),
        );
      }
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final name = (file.name.isNotEmpty) ? file.name : 'trufit_restore.zip';
    final safeName = name.toLowerCase().endsWith('.zip') ? name : '$name.zip';
    final tempFile = File(
      '${tempDir.path}/picked_${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );
    await tempFile.writeAsBytes(bytes, flush: true);
    return tempFile.path;
  }

  Future<void> _handleVerifyBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final path = await _resolvePickedZipPath(result.files.single);
    if (path == null) return;

    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      var verify = await backupService.verifyBackup(path);

      if (!mounted) return;

      if (verify.isEncrypted && !verify.isValid) {
        setState(() => _isLoading = false);
        final pwd = await _promptForPassword();
        if (pwd == null || pwd.isEmpty) return;

        setState(() => _isLoading = true);
        verify = await backupService.verifyBackup(path, password: pwd);
        if (!mounted) return;
      }

      if (verify.isValid) {
        // ignore: unawaited_futures
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Backup Verified ✨',
              style: context.text.body.copyWith(color: context.colors.green),
            ),
            content: Text(
              'App Version: ${verify.appVersion}\n'
              'Created At: ${verify.createdAt != 'Unknown' ? DateFormat('MMM dd, yyyy · HH:mm').format(DateTime.parse(verify.createdAt)) : 'Unknown'}\n'
              'Entries: ${verify.totalEntries}\n'
              'Photos: ${verify.photoCount}\n\n'
              'Your current data was not touched.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Awesome'),
              ),
            ],
          ),
        );
      } else {
        // ignore: unawaited_futures
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Verification Failed',
              style: context.text.body.copyWith(color: context.colors.red),
            ),
            content: Text(verify.errorMessage ?? 'Invalid backup file.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // ignore: unawaited_futures
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Verification Error',
              style: context.text.body.copyWith(color: context.colors.red),
            ),
            content: Text('An error occurred while verifying the backup: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final path = await _resolvePickedZipPath(result.files.single);
    if (path == null) return;

    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      var verify = await backupService.verifyBackup(path);

      if (!mounted) return;

      String? passwordUsed;
      if (verify.isEncrypted && !verify.isValid) {
        setState(() => _isLoading = false);
        passwordUsed = await _promptForPassword();
        if (passwordUsed == null || passwordUsed.isEmpty) return;

        setState(() => _isLoading = true);
        verify = await backupService.verifyBackup(path, password: passwordUsed);
        if (!mounted) return;
      }

      if (!verify.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verify.errorMessage ?? 'Invalid backup file.'),
            backgroundColor: context.colors.red,
          ),
        );
        return;
      }

      final warningText = (verify.errorMessage != null)
          ? '\n\n${verify.errorMessage}'
          : '';

      final shouldRestore =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Restore Backup?'),
              content: Text(
                'App Version: ${verify.appVersion}\n'
                'Created At: ${verify.createdAt != 'Unknown' ? DateFormat('MMM dd, yyyy · HH:mm').format(DateTime.parse(verify.createdAt)) : 'Unknown'}\n'
                'Entries: ${verify.totalEntries}\n'
                'Photos: ${verify.photoCount}\n\n'
                'Restoring replaces this account\'s local records and, when signed in, its synced cloud snapshot. Cloud records absent from the backup will be removed. A verified safety backup must succeed before anything is replaced. Device preferences and credentials stay unchanged.'
                '$warningText',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Restore',
                    style: context.text.body.copyWith(
                      color: context.colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldRestore) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final result = await backupService.restoreBackup(
          path,
          password: passwordUsed,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result.localCommitted) {
          ref.invalidate(profileProvider);
          ref.invalidate(dailyLogProvider);
        }
        if (result.success) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text(
                result.failedPhotosCount > 0
                    ? 'Restore Complete (with errors)'
                    : 'Restore Complete 🎉',
                style: context.text.body.copyWith(
                  color: result.failedPhotosCount > 0
                      ? context.colors.orange
                      : context.colors.green,
                ),
              ),
              content: Text(
                result.failedPhotosCount > 0
                    ? 'Your records were restored. ${result.failedPhotosCount} referenced photos were unavailable in this backup.'
                    : 'Restore complete. Your data has been loaded.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Failed to restore backup.'),
              backgroundColor: context.colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString().replaceFirst('FormatException: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore error: $errorMsg'),
              backgroundColor: context.colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: context.colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isLoading,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Spacing.screen,
                Spacing.section,
                Spacing.screen,
                shellScrollBottomPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.cardPad),
                    decoration: BoxDecoration(
                      color: context.colors.card,
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Last Backup',
                              style: context.text.body.copyWith(
                                color: context.colors.textMedium,
                              ),
                            ),
                            if (_isLastBackupEncrypted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: context.colors.textMedium,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastBackupDate,
                          style: context.text.bodyStrong.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                        if (_lastBackupSize.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _lastBackupSize,
                            style: context.text.micro.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Last Auto-Backup (Weekly)',
                          style: context.text.body.copyWith(
                            color: context.colors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastAutoBackupDate,
                          style: context.text.bodyStrong.copyWith(
                            color: context.colors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.section),
                  SettingsRow(
                    title: 'Encrypt Backup',
                    subtitle: 'Protect your backup with a password',
                    icon: Icons.lock_outline_rounded,
                    showChevron: false,
                    trailing: Switch(
                      value: _encryptBackup,
                      activeTrackColor: context.colors.primary,
                      onChanged: (val) {
                        setState(() {
                          _encryptBackup = val;
                          if (!val) _passwordController.clear();
                        });
                      },
                    ),
                  ),
                  if (_encryptBackup) ...[
                    const SizedBox(height: Spacing.textPair),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: context.text.body.copyWith(
                        color: context.colors.textDark,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Backup Password',
                        labelStyle: context.text.body.copyWith(
                          color: context.colors.textMedium,
                        ),
                        filled: true,
                        fillColor: context.colors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.chip),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.stack),
                  SettingsRow(
                    title: 'Create Backup',
                    subtitle: 'Account records and available photos',
                    icon: Icons.upload_file_rounded,
                    onTap: _handleCreateBackup,
                  ),
                  const SizedBox(height: Spacing.stack),
                  SettingsRow(
                    title: 'Restore from Backup',
                    subtitle: 'Overwrite current data with a backup',
                    leadingContent: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.pinkIcon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Radii.chip),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.restore_page_rounded,
                          color: context.colors.pinkIcon,
                          size: IconSize.row,
                        ),
                      ),
                    ),
                    onTap: _handleRestoreBackup,
                  ),
                  const SizedBox(height: Spacing.stack),
                  SettingsRow(
                    title: 'Verify Backup',
                    subtitle: 'Test a backup file without restoring',
                    leadingContent: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.mintIcon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Radii.chip),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fact_check_rounded,
                          color: context.colors.mintIcon,
                          size: IconSize.row,
                        ),
                      ),
                    ),
                    onTap: _handleVerifyBackup,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: context.colors.scaffoldBg,
                color: context.colors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
