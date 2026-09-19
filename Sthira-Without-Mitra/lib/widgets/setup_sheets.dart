import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../providers/app_providers.dart';
import '../providers/credential_provider.dart';
import 'app_bottom_sheet.dart';
import 'app_text_field.dart';
import 'primary_button.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../theme/app_motion.dart';

class AiSetupSheet extends ConsumerStatefulWidget {
  const AiSetupSheet({super.key});

  @override
  ConsumerState<AiSetupSheet> createState() => _AiSetupSheetState();
}

class _AiSetupSheetState extends ConsumerState<AiSetupSheet> {
  late TextEditingController _geminiController;
  late TextEditingController _coachController;
  bool _isVerifying = false;
  bool _isSuccess = false;
  String _errorMessage = '';
  bool _obscureKey = true;

  int _attemptToken = 0;
  late int _initialGeneration;

  @override
  void initState() {
    super.initState();
    _initialGeneration = ref.read(accountGenerationProvider);
    final profile = ref.read(profileProvider);
    final cred = ref.read(credentialProvider);
    _geminiController = TextEditingController(text: cred.key ?? '');
    _coachController = TextEditingController(text: profile.coachName ?? '');
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _coachController.dispose();
    super.dispose();
  }

  void _edited(String _) {
    _attemptToken++;
    setState(() {
      _isVerifying = false;
      _isSuccess = false;
      _errorMessage = '';
    });
  }

  Future<void> _save() async {
    if (_isVerifying) return;
    if (ref.read(accountGenerationProvider) != _initialGeneration) {
      setState(
        () =>
            _errorMessage = 'Account changed. Reopen AI settings to continue.',
      );
      return;
    }
    final key = _geminiController.text.trim();
    final coach = _coachController.text.trim();
    final currentToken = ++_attemptToken;
    final generation = ref.read(accountGenerationProvider);
    bool isCurrent() =>
        mounted &&
        currentToken == _attemptToken &&
        ref.read(accountGenerationProvider) == generation &&
        _geminiController.text.trim() == key &&
        _coachController.text.trim() == coach;
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });
    try {
      if (key.isNotEmpty) {
        await ref.read(geminiFoodServiceProvider).verifyApiKey(key);
        if (!isCurrent()) return;
        await ref.read(credentialProvider.notifier).saveKey(key);
      } else {
        await ref.read(credentialProvider.notifier).removeKey();
      }
      if (!isCurrent()) return;
      final current = ref.read(profileProvider);
      await ref
          .read(profileProvider.notifier)
          .updateProfile(current.copyWith(coachName: coach));
      if (!isCurrent()) return;
      setState(() => _isSuccess = true);
      if (!(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
        await Future<void>.delayed(Motion.deliberate);
      }
      if (isCurrent()) Navigator.pop(context, true);
    } catch (error) {
      if (isCurrent()) {
        setState(
          () => _errorMessage = error
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('AiException: ', ''),
        );
      }
    } finally {
      if (mounted && currentToken == _attemptToken) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'AI & Coach Settings',
      scrollable: true,
      subtitle:
          'Set your coach\'s name. Food scanning and coach features use your Gemini API key.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _coachController,
            onChanged: _edited,
            labelText: 'Coach name',
            hintText: 'Eg. Shravan',
            capitalization: TextCapitalization.words,
            prefixIcon: Icons.sports_rounded,
          ),
          const SizedBox(height: Spacing.block),
          AppTextField(
            controller: _geminiController,
            onChanged: _edited,
            labelText: 'Gemini API Key',
            hintText: 'AI Studio Key...',
            obscureText: _obscureKey,
            prefixIcon: Icons.key_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureKey
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: context.colors.textMedium,
              ),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: context.colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: context.text.caption.copyWith(
                        color: context.colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  _launchUrl('https://aistudio.google.com/app/apikey'),
              icon: Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: context.colors.primary,
              ),
              label: Text(
                'Get Gemini API Key',
                style: context.text.body.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.section),
          PrimaryButton(
                onPressed: _isSuccess ? () {} : (_isVerifying ? null : _save),
                label: _isSuccess
                    ? 'Saved!'
                    : (_isVerifying ? 'Verifying...' : 'Save Changes'),
                isLoading: _isVerifying,
                icon: _isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.check_rounded,
                iconColor: _isSuccess ? const Color(0xFF4CAF50) : null,
              )
              .animate(target: _isSuccess ? 1 : 0)
              .scaleXY(
                end: 1.05,
                duration: Motion.standard,
                curve: Motion.enter,
              )
              .then(delay: Motion.standard)
              .scaleXY(end: 1.0, duration: Motion.instant),
        ],
      ),
    );
  }
}

class HealthConnectSheet extends ConsumerStatefulWidget {
  const HealthConnectSheet({super.key});

  @override
  ConsumerState<HealthConnectSheet> createState() => _HealthConnectSheetState();
}

class _HealthConnectSheetState extends ConsumerState<HealthConnectSheet> {
  bool _connecting = false;
  String _status = '';

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _status = '';
    });
    try {
      final hcService = ref.read(healthConnectServiceProvider);
      final generation = ref.read(accountGenerationProvider);

      final available = await hcService.isAvailable();
      if (!available) {
        if (mounted) {
          setState(() {
            _status = 'Health Connect is not installed on this device.';
          });
        }
        return;
      }

      await hcService.requestPermission();

      // Re-read effective status (Android process death workaround)
      final authorized = await hcService.isAuthorized();
      final hasData = await hcService.canReadSteps();

      if (mounted && generation == ref.read(accountGenerationProvider)) {
        if (authorized || hasData) {
          ref.read(syncControllerProvider.notifier).sync();
          setState(() {
            _status = 'Connected! Your readings are syncing.';
          });
          Future.delayed(Motion.deliberate, () {
            if (mounted) Navigator.pop(context, true);
          });
        } else {
          setState(() {
            _status =
                'Health access was not granted. You can try again or enter data manually.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Failed to connect. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Health Connect',
      subtitle: 'Automatically sync steps and sleep data from other apps.',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.favorite_rounded, size: 64, color: context.colors.primary),
          const SizedBox(height: Spacing.section),
          PrimaryButton(
            onPressed: _connecting ? null : _connect,
            label: _connecting ? 'Connecting...' : 'Connect Now',
            isLoading: _connecting,
            icon: Icons.link_rounded,
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: context.text.body.copyWith(
                color: _status.contains('Connected')
                    ? context.colors.primary
                    : context.colors.red,
              ),
            ),
            if (!_status.contains('Connected')) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (mounted) Navigator.pop(context, false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textMedium,
                ),
                child: const Text('Enter Data Manually Instead'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class CloudSyncSheet extends ConsumerStatefulWidget {
  const CloudSyncSheet({super.key});

  @override
  ConsumerState<CloudSyncSheet> createState() => _CloudSyncSheetState();
}

class _CloudSyncSheetState extends ConsumerState<CloudSyncSheet> {
  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(cloudSyncControllerProvider);
    final isSyncing = syncState == CloudSyncState.syncing;
    final isSuccess = syncState == CloudSyncState.success;
    final errorMessage = ref
        .read(cloudSyncControllerProvider.notifier)
        .errorMessage;

    ref.listen(cloudSyncControllerProvider, (prev, next) {
      if (next == CloudSyncState.success) {
        Future.delayed(Motion.deliberate, () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    });
    return AppSheet(
      title: 'Cloud Backup',
      subtitle:
          'Securely sync your progress across devices and never lose a day.',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.cloud_sync_rounded,
            size: 64,
            color: context.colors.primary,
          ),
          const SizedBox(height: Spacing.section),
          PrimaryButton(
            onPressed: isSyncing || isSuccess
                ? null
                : () => ref
                      .read(cloudSyncControllerProvider.notifier)
                      .signInAndSync(),
            label: isSyncing
                ? 'Syncing...'
                : isSuccess
                ? 'Synced!'
                : 'Enable Cloud Sync',
            isLoading: isSyncing,
            icon: isSuccess
                ? Icons.check_circle_rounded
                : Icons.cloud_upload_rounded,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: context.text.body.copyWith(color: context.colors.red),
            ),
          ],
          if (isSuccess) ...[
            const SizedBox(height: 16),
            Text(
              'Connected! Your data is securely backed up.',
              textAlign: TextAlign.center,
              style: context.text.body.copyWith(color: context.colors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
