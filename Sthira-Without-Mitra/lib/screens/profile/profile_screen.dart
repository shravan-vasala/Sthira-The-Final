import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_client.dart';
import '../../services/ai_logger.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/setup_sheets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/target_estimate_sheet.dart';
import '../../utils/target_calculator.dart';
import 'widgets/trophy_room_card.dart';
import 'widgets/journey_stats_strip.dart';
import '../../providers/app_providers.dart';
import '../../widgets/gita_verse_sheet.dart';
import '../../widgets/profile_avatar.dart';
import '../../theme/layout_insets.dart';
import '../../providers/badge_engine_provider.dart';
import '../../providers/credential_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../services/screen_time_service.dart';
import '../../widgets/avatar_picker_sheet.dart';
import '../../services/diagnostic_logger.dart';
import '../home/share_preview_sheet.dart';
import '../../widgets/settings_row.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _appVersion = '';
  int _devTapCount = 0;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${info.version}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            Spacing.screen,
            Spacing.section,
            Spacing.screen,
            shellScrollBottomPadding(context),
          ),
          child: Column(
            children: [
              // Profile header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.cardPadTight),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(Radii.card),
                ),
                child: Column(
                  children: [
                    // Avatar
                    _ProfileAvatarAction(
                      label: 'Change avatar',
                      onTap: () async {
                        final result = await showAppBottomSheet<String>(
                          context: context,
                          builder: (_) => AvatarPickerSheet(
                            currentAvatar: profile.photoPath,
                          ),
                        );
                        if (result != null) {
                          try {
                            if (result == 'DELETE') {
                              await ref
                                  .read(profileProvider.notifier)
                                  .updateProfile(
                                    profile.copyWith(clearPhoto: true),
                                  );
                            } else {
                              await ref
                                  .read(profileProvider.notifier)
                                  .updateProfile(
                                    profile.copyWith(photoPath: result),
                                  );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update avatar: $e'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        foregroundDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.border,
                            width: 1.5,
                          ),
                        ),
                        child: ProfileAvatar(
                          name: profile.name,
                          photoPath: profile.photoPath,
                          size: 72,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.stack),
                    Text(
                      profile.name,
                      style: context.text.screenTitle.copyWith(
                        color: context.colors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Height: ${profile.height != null ? "${profile.height!.toStringAsFixed(0)} cm" : "Not set"}',
                      style: context.text.body.copyWith(
                        color: context.colors.textMedium,
                      ),
                    ),
                    if (profile.targetWeight != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${(profile.useKg ? profile.targetWeight! : profile.targetWeight! * 2.20462).toStringAsFixed(1)} ${profile.weightUnit}',
                        style: context.text.body.copyWith(
                          color: context.colors.textMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Spacing.section),

              // Journey Stats Strip
              const JourneyStatsStrip(),
              const SizedBox(height: Spacing.section),

              // Cloud Sync
              const _CloudSyncCard(),
              const SizedBox(height: Spacing.stack),

              if (ref.watch(badgesProvider).isNotEmpty) ...[
                const TrophyRoomCard(),
                const SizedBox(height: Spacing.stack),
              ],

              // Menu items
              SettingsRow(
                icon: Icons.edit_rounded,
                title: 'Edit Profile',
                subtitle: 'Name, height, target weight',
                onTap: () {
                  showAppBottomSheet(
                    context: context,
                    builder: (ctx) => const _EditProfileSheet(),
                  );
                },
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Settings',
                subtitle: 'Coach name & Gemini API key',
                onTap: () => showAppBottomSheet(
                  context: context,
                  builder: (_) => const AiSetupSheet(),
                ),
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.history_rounded,
                title: 'Recent AI Activity',
                subtitle: 'View local diagnostic logs',
                onTap: () => showAppBottomSheet(
                  context: context,
                  builder: (_) => const _AiActivitySheet(),
                ),
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.fitness_center_rounded,
                title: 'Manage Plans',
                subtitle: 'Edit workout & meal JSON',
                onTap: () => context.go('/profile/manage-plans'),
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.notifications_rounded,
                title: 'Reminders',
                subtitle: 'Daily habits, workouts, and backups',
                onTap: () => context.go('/profile/reminders'),
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.swap_horiz_rounded,
                title: 'Unit Preference',
                subtitle:
                    'Currently: ${profile.useKg ? 'Kilograms (kg)' : 'Pounds (lb)'}',
                onTap: () => _showUnitDialog(context, ref),
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.dark_mode_rounded,
                title: 'Theme',
                subtitle:
                    'Currently: ${_themeLabel(ref.watch(themeModeProvider))}',
                onTap: () => _showThemeDialog(context, ref),
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.volume_up_rounded,
                title: 'Rest Timer Sound',
                subtitle: 'Play alert sound when rest finishes',
                showChevron: false,
                trailing: Switch(
                  value: profile.restTimerSound,
                  activeColor: context.colors.primary,
                  onChanged: (val) {
                    ref
                        .read(profileProvider.notifier)
                        .updateProfile(profile.copyWith(restTimerSound: val));
                  },
                ),
              ),
              const SizedBox(height: Spacing.stack),
              if (Platform.isAndroid) ...[
                SettingsRow(
                  icon: Icons.smartphone_rounded,
                  title: 'Screen Time Tracking',
                  subtitle: profile.screenTimeEnabled
                      ? 'Enabled (Tracks device screen time)'
                      : 'Disabled (Opt-in to track screen time)',
                  showChevron: false,
                  trailing: Switch(
                    value: profile.screenTimeEnabled,
                    activeColor: context.colors.primary,
                    onChanged: (val) async {
                      if (val) {
                        // Attempt to enable
                        final hasPermission = await ref
                            .read(screenTimeServiceProvider)
                            .checkPermission();
                        if (hasPermission) {
                          // ignore: unawaited_futures
                          ref
                              .read(profileProvider.notifier)
                              .updateProfile(
                                profile.copyWith(screenTimeEnabled: true),
                              );
                        } else {
                          if (context.mounted) {
                            _showScreenTimePermissionDialog(
                              context,
                              ref,
                              profile,
                            );
                          }
                        }
                      } else {
                        // Disable
                        // ignore: unawaited_futures
                        ref
                            .read(profileProvider.notifier)
                            .updateProfile(
                              profile.copyWith(screenTimeEnabled: false),
                            );
                      }
                    },
                  ),
                ),
                const SizedBox(height: Spacing.stack),
              ],
              SettingsRow(
                icon: Icons.vibration_rounded,
                title: 'Rest Timer Vibration',
                subtitle: 'Vibrate when rest finishes',
                showChevron: false,
                trailing: Switch(
                  value: profile.restTimerVibration,
                  activeColor: context.colors.primary,
                  onChanged: (val) {
                    ref
                        .read(profileProvider.notifier)
                        .updateProfile(
                          profile.copyWith(restTimerVibration: val),
                        );
                  },
                ),
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.backup_rounded,
                title: 'Backup & Restore',
                subtitle: 'Export or restore all data & photos',
                onTap: () {
                  context.go('/profile/backup-restore');
                },
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.ios_share_rounded,
                title: 'Share Progress',
                subtitle: 'Generate a progress summary card',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const SharePreviewSheet(),
                  );
                },
              ),
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.table_chart_rounded,
                title: 'Export Data',
                subtitle: 'Download logs and stats as CSV',
                onTap: () => _showExportDataSheet(context, ref),
              ),
              const SizedBox(height: 16),
              const GitaReflectionButton(),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  _devTapCount++;
                  if (_devTapCount >= 7) {
                    _devTapCount = 0;
                    showAppBottomSheet(
                      context: context,
                      builder: (ctx) => const _SystemDiagnosticsSheet(),
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Made with ',
                          style: context.text.micro.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                        Icon(
                          Icons.eco_rounded,
                          size: 14,
                          color: context.colors.primary,
                        ),
                        Text(
                          ' for Bodamma',
                          style: context.text.micro.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_appVersion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _appVersion,
                        style: context.text.micro.copyWith(
                          color: context.colors.textLight.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showScreenTimePermissionDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.card,
        title: Text(
          'Enable Screen Time',
          style: context.text.screenTitle.copyWith(
            color: context.colors.textDark,
          ),
        ),
        content: Text(
          'Sthira can read your daily screen time to help you build better habits. '
          'This requires "Usage Access" permission.\n\n'
          'Your screen time is only stored locally on this device, and will only be synced to your private cloud if Cloud Sync is enabled.',
          style: context.text.body.copyWith(color: context.colors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: context.text.body.copyWith(
                color: context.colors.textLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(screenTimeServiceProvider).openSettings();
            },
            child: Text(
              'Open Settings',
              style: context.text.body.copyWith(color: context.colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnitDialog(BuildContext context, WidgetRef ref) {
    showAppBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final profile = ref.watch(profileProvider);
            final colors = context.colors;

            return AppSheet(
              title: 'Select Unit Preference',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [true, false].map((isKg) {
                  final selected = profile.useKg == isKg;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.stack),
                    child: SettingsRow(
                      icon: isKg
                          ? Icons.monitor_weight_rounded
                          : Icons.scale_rounded,
                      title: isKg ? 'Kilograms (kg)' : 'Pounds (lb)',
                      subtitle: isKg ? 'Metric system' : 'Imperial system',
                      showChevron: false,
                      trailing: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? colors.primary : colors.border,
                      ),
                      onTap: () async {
                        if (profile.useKg != isKg) {
                          await ref.read(profileProvider.notifier).toggleUnit();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Unit preference updated'),
                              ),
                            );
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showAppBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final current = ref.watch(themeModeProvider);
            final colors = context.colors;

            String label(ThemeMode mode) {
              switch (mode) {
                case ThemeMode.system:
                  return 'System';
                case ThemeMode.light:
                  return 'Light';
                case ThemeMode.dark:
                  return 'Dark';
              }
            }

            String subtitle(ThemeMode mode) {
              switch (mode) {
                case ThemeMode.system:
                  return 'Match phone settings';
                case ThemeMode.light:
                  return 'Always light';
                case ThemeMode.dark:
                  return 'Always dark';
              }
            }

            IconData icon(ThemeMode mode) {
              switch (mode) {
                case ThemeMode.system:
                  return Icons.brightness_auto_rounded;
                case ThemeMode.light:
                  return Icons.light_mode_rounded;
                case ThemeMode.dark:
                  return Icons.dark_mode_rounded;
              }
            }

            return AppSheet(
              title: 'Select Theme',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ThemeMode.values.map((mode) {
                  final selected = current == mode;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.stack),
                    child: SettingsRow(
                      icon: icon(mode),
                      title: label(mode),
                      subtitle: subtitle(mode),
                      showChevron: false,
                      trailing: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? colors.primary : colors.border,
                      ),
                      onTap: () async {
                        if (current != mode) {
                          await ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(mode);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Theme preference updated'),
                              ),
                            );
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _showExportDataSheet(BuildContext context, WidgetRef ref) {
    showAppBottomSheet(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: 'Export Data (CSV)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsRow(
              title: 'Last 30 Days (Inclusive)',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _handleExport(
                  context,
                  ref,
                  DateTime.now().subtract(const Duration(days: 29)),
                );
              },
            ),
            const SizedBox(height: Spacing.stack),
            SettingsRow(
              title: 'Last 90 Days (Inclusive)',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _handleExport(
                  context,
                  ref,
                  DateTime.now().subtract(const Duration(days: 89)),
                );
              },
            ),
            const SizedBox(height: Spacing.stack),
            SettingsRow(
              title: 'All Time',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _handleExport(context, ref, null);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    DateTime? startDate,
  ) async {
    if (!context.mounted) return;

    BuildContext? dialogContext;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final exportService = ref.read(csvExportServiceProvider);
      final result = await exportService.exportData(startDate);

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop(); // Explicitly pop dialog only
      }

      if (!context.mounted) return;

      if (result.isSuccess && result.filePath != null) {
        try {
          // ignore: deprecated_member_use
          await Share.shareXFiles([
            XFile(result.filePath!),
          ], text: 'Sthira Data Export');
        } catch (shareErr) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to share: $shareErr')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to export data.'),
            backgroundColor: context.colors.red,
          ),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export error: $e'),
          backgroundColor: context.colors.red,
        ),
      );
    }
  }
}

class _CloudSyncCard extends ConsumerStatefulWidget {
  const _CloudSyncCard();

  @override
  ConsumerState<_CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends ConsumerState<_CloudSyncCard> {
  @override
  Widget build(BuildContext context) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final userEmail = ref.watch(userEmailProvider);
    final syncState = ref.watch(cloudSyncControllerProvider);
    final isSyncing = syncState == CloudSyncState.syncing;
    final errorMessage = ref
        .read(cloudSyncControllerProvider.notifier)
        .errorMessage;

    final pendingCountAsync = ref.watch(syncPendingCountProvider);
    final pendingCount = pendingCountAsync.value ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Spacing.block,
            runSpacing: Spacing.inline,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_sync_rounded,
                    color: context.colors.primary,
                    size: IconSize.inline,
                  ),
                  const SizedBox(width: Spacing.inline),
                  Text('Cloud Sync', style: context.text.cardTitle),
                ],
              ),
              if (isSignedIn)
                Text(
                  isSyncing
                      ? 'Syncing'
                      : errorMessage != null
                      ? 'Needs attention'
                      : pendingCount > 0
                      ? 'Pending'
                      : 'Connected',
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSignedIn
                ? 'Signed in as $userEmail. Text records sync when connected; photos stay on this device.'
                : 'Sign in to sync your text data across devices. Photos are NOT cloud-synced.',
            style: context.text.caption.copyWith(
              color: context.colors.textMedium,
            ),
          ),
          if (isSignedIn && pendingCount > 0 && !isSyncing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.sync_problem_rounded,
                  color: context.colors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pendingCount pending edits not yet synced',
                    style: context.text.caption.copyWith(
                      color: context.colors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error: $errorMessage',
              style: context.text.micro.copyWith(color: context.colors.red),
            ),
          ],
          const SizedBox(height: 16),
          if (isSyncing)
            Center(
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Syncing data...',
                    style: context.text.micro.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            )
          else if (!isSignedIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref
                    .read(cloudSyncControllerProvider.notifier)
                    .signInAndSync(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign in with Google'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pendingCount == 0
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(firestoreSyncServiceProvider)
                                  .flushNow();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sync failed: $e')),
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      side: BorderSide(
                        color: pendingCount > 0
                            ? context.colors.primary
                            : context.colors.primary.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(
                      pendingCount > 0
                          ? 'Sync $pendingCount Edits'
                          : 'Up to date',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () async {
                    if (pendingCount > 0) {
                      final force = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: context.colors.card,
                          title: Text(
                            'Unsynced Changes',
                            style: context.text.body.copyWith(
                              color: context.colors.textDark,
                            ),
                          ),
                          content: Text(
                            'You have $pendingCount unsynced edits. Signing out now means they will stay locally but won\'t be in the cloud. Proceed?',
                            style: context.text.body.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: context.text.body.copyWith(
                                  color: context.colors.textLight,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Sign Out Anyway',
                                style: context.text.body.copyWith(
                                  color: context.colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (force != true) return;
                    } else {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: context.colors.card,
                          title: Text(
                            'Sign Out',
                            style: context.text.body.copyWith(
                              color: context.colors.textDark,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to sign out?',
                            style: context.text.body.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: context.text.body.copyWith(
                                  color: context.colors.textLight,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Sign Out',
                                style: context.text.body.copyWith(
                                  color: context.colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                    }
                    await ref.read(remindersProvider.notifier).clearOnSignOut();
                    await ref.read(accountSessionProvider).signOut();
                  },
                  tooltip: 'Sign out',
                  icon: Icon(Icons.logout_rounded, color: context.colors.red),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.red.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController nameController;
  late TextEditingController coachNameController;
  late TextEditingController heightController;
  late TextEditingController targetController;
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController carbsController;
  late TextEditingController fatController;

  String? _localPhotoPath;
  bool _clearPhoto = false;
  bool _isSaving = false;
  bool _isEstimating = false;
  TargetEstimateInputs? _targetInputs;
  late final int _accountGeneration;
  final _fieldErrors = <String, String>{};

  @override
  void initState() {
    super.initState();
    _accountGeneration = ref.read(accountGenerationProvider);
    final profile = ref.read(profileProvider);
    nameController = TextEditingController(text: profile.name);
    coachNameController = TextEditingController(text: profile.coachName);
    heightController = TextEditingController(
      text: profile.height?.toStringAsFixed(0) ?? '',
    );
    double? displayTarget = profile.targetWeight;
    if (displayTarget != null && !profile.useKg) {
      displayTarget = displayTarget * 2.20462;
    }
    targetController = TextEditingController(
      text: displayTarget?.toStringAsFixed(1) ?? '',
    );
    caloriesController = TextEditingController(
      text: profile.targetCalories.toString(),
    );
    proteinController = TextEditingController(
      text: profile.targetProteinG.toString(),
    );
    carbsController = TextEditingController(
      text: profile.targetCarbsG.toString(),
    );
    fatController = TextEditingController(text: profile.targetFatG.toString());
    _localPhotoPath = profile.photoPath;
  }

  @override
  void dispose() {
    nameController.dispose();
    coachNameController.dispose();
    heightController.dispose();
    targetController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    super.dispose();
  }

  bool get _canEstimate =>
      mounted &&
      ref.read(accountGenerationProvider) == _accountGeneration &&
      !ref.read(accountTransitionProvider) &&
      !ref.read(accountHydratingProvider);

  Future<void> _suggestTargets() async {
    if (_isSaving || _isEstimating || !_canEstimate) return;
    final profile = ref.read(profileProvider);
    final draft = _targetInputs;
    final height = double.tryParse(heightController.text.trim());
    setState(() => _isEstimating = true);
    try {
      final estimate = await showAppBottomSheet<TargetEstimate>(
        context: context,
        builder: (_) => TargetEstimateSheet(
          initialInputs: TargetEstimateInputs(
            heightCm:
                height ?? profile.height ?? TargetCalculator.defaultHeightCm,
            weightKg:
                draft?.weightKg ??
                profile.currentWeight ??
                TargetCalculator.defaultWeightKg,
            age: draft?.age ?? profile.age ?? TargetCalculator.defaultAge,
            gender:
                draft?.gender ??
                profile.gender ??
                TargetCalculator.defaultGender,
            activityLevel:
                draft?.activityLevel ??
                TargetCalculator.normalizeActivityLevel(profile.activityLevel),
            goal:
                draft?.goal ??
                TargetCalculator.normalizeGoal(profile.primaryGoal),
          ),
          useKg: profile.useKg,
        ),
      );
      if (estimate == null || !_canEstimate) return;
      setState(() {
        _targetInputs = estimate.inputs;
        heightController.text = estimate.inputs.heightCm.toString();
        caloriesController.text = estimate.targets.calories.toString();
        proteinController.text = estimate.targets.proteinG.toString();
        carbsController.text = estimate.targets.carbsG.toString();
        fatController.text = estimate.targets.fatG.toString();
        for (final field in ['height', 'calories', 'protein', 'carbs', 'fat']) {
          _fieldErrors.remove(field);
        }
      });
    } finally {
      if (mounted) setState(() => _isEstimating = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null ||
          !mounted ||
          ref.read(accountGenerationProvider) != _accountGeneration)
        return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            // ignore: use_build_context_synchronously
            toolbarColor: context.colors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null &&
          mounted &&
          ref.read(accountGenerationProvider) == _accountGeneration) {
        final mediaRepo = ref.read(mediaRepoProvider);
        final relativePath = await mediaRepo.saveMediaFile(
          croppedFile.path,
          'profile_photos',
        );

        if (!mounted ||
            ref.read(accountGenerationProvider) != _accountGeneration)
          return;
        setState(() {
          _localPhotoPath = relativePath;
          _clearPhoto = false;
        });

        // Clean up abandoned temp crops
        File(croppedFile.path).delete().ignore();
      }

      File(pickedFile.path).delete().ignore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: context.colors.red,
          ),
        );
      }
    }
  }

  void _showPickerOptions() {
    showAppBottomSheet(
      context: context,
      builder: (ctx) => AppSheet(
        title: 'Profile Photo',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsRow(
              icon: Icons.camera_alt_rounded,
              title: 'Take a picture',
              showChevron: false,
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: Spacing.stack),
            SettingsRow(
              icon: Icons.photo_library_rounded,
              title: 'Choose from gallery',
              showChevron: false,
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: Spacing.stack),
            SettingsRow(
              icon: Icons.pets_rounded,
              title: 'Choose preset avatar',
              showChevron: false,
              onTap: () async {
                Navigator.pop(ctx);
                final selectedAvatar = await showAppBottomSheet<String>(
                  context: context,
                  builder: (_) => AvatarPickerSheet(
                    currentAvatar:
                        _localPhotoPath ?? ref.read(profileProvider).photoPath,
                  ),
                );
                if (selectedAvatar == 'DELETE') {
                  setState(() {
                    _localPhotoPath = null;
                    _clearPhoto = true;
                  });
                } else if (selectedAvatar != null) {
                  setState(() {
                    _localPhotoPath = selectedAvatar;
                    _clearPhoto = false;
                  });
                }
              },
            ),
            if (_localPhotoPath != null && !_clearPhoto) ...[
              const SizedBox(height: Spacing.stack),
              SettingsRow(
                icon: Icons.delete_rounded,
                title: 'Remove photo',
                showChevron: false,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() {
                    _localPhotoPath = null;
                    _clearPhoto = true;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(accountGenerationProvider) != _accountGeneration) {
      return const AppSheet(
        title: 'Account changed',
        child: Text('Reopen Edit profile for this account.'),
      );
    }
    final profile = ref.watch(profileProvider);
    final accountBusy =
        ref.watch(accountTransitionProvider) ||
        ref.watch(accountHydratingProvider);

    return AppSheet(
      title: 'Edit Profile',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _ProfileAvatarAction(
              label: 'Change profile photo',
              onTap: _showPickerOptions,
              child: Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.insetSurface,
                    ),
                    foregroundDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.border,
                        width: 1.5,
                      ),
                    ),
                    child: ProfileAvatar(
                      name: nameController.text,
                      photoPath: _clearPhoto ? null : _localPhotoPath,
                      size: 72,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: context.colors.onPrimary,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ProfileTextField(
            label: 'Name',
            controller: nameController,
            prefixIcon: Icons.person_rounded,
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            label: 'Coach name',
            controller: coachNameController,
            prefixIcon: Icons.sports_rounded,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            label: 'Height (cm)',
            controller: heightController,
            errorText: _fieldErrors['height'],
            prefixIcon: Icons.height_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _ProfileTextField(
            label: profile.useKg ? 'Target Weight (kg)' : 'Target Weight (lb)',
            controller: targetController,
            errorText: _fieldErrors['target'],
            prefixIcon: Icons.flag_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _isSaving || _isEstimating || accountBusy
                ? null
                : _suggestTargets,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Suggest for me'),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.primary,
            ),
          ),
          const SizedBox(height: Spacing.inline),
          _ProfileTextField(
            label: 'Target Daily Calories',
            controller: caloriesController,
            errorText: _fieldErrors['calories'],
            prefixIcon: Icons.restaurant_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Text(
            'Daily macros (g)',
            style: context.text.caption.copyWith(
              color: context.colors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack =
                  constraints.maxWidth < 500 ||
                  MediaQuery.textScalerOf(context).scale(15) > 20;
              return Wrap(
                spacing: Spacing.inline,
                runSpacing: Spacing.block,
                children: [
                  for (final item in [
                    (
                      'Protein',
                      proteinController,
                      Icons.fitness_center_rounded,
                    ),
                    ('Carbs', carbsController, Icons.breakfast_dining_rounded),
                    ('Fat', fatController, Icons.water_drop_rounded),
                  ])
                    SizedBox(
                      width: stack
                          ? constraints.maxWidth
                          : (constraints.maxWidth - Spacing.inline * 2) / 3,
                      child: _ProfileTextField(
                        label: item.$1,
                        controller: item.$2,
                        errorText: _fieldErrors[item.$1.toLowerCase()],
                        prefixIcon: item.$3,
                        keyboardType: TextInputType.number,
                        compact: !stack,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Save',
            isLoading: _isSaving,
            onPressed: _isSaving || _isEstimating
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    try {
                      final heightText = heightController.text.trim();
                      final targetText = targetController.text.trim();
                      final calText = caloriesController.text.trim();
                      final proText = proteinController.text.trim();
                      final carText = carbsController.text.trim();
                      final fatText = fatController.text.trim();

                      final parsedHeight = heightText.isEmpty
                          ? null
                          : double.tryParse(heightText);
                      final parsedTarget = targetText.isEmpty
                          ? null
                          : double.tryParse(targetText);
                      final parsedCal = calText.isEmpty
                          ? null
                          : int.tryParse(calText);
                      final parsedPro = proText.isEmpty
                          ? null
                          : int.tryParse(proText);
                      final parsedCar = carText.isEmpty
                          ? null
                          : int.tryParse(carText);
                      final parsedFat = fatText.isEmpty
                          ? null
                          : int.tryParse(fatText);

                      final errors = <String, String>{};
                      if (heightText.isNotEmpty &&
                          (parsedHeight == null ||
                              !parsedHeight.isFinite ||
                              parsedHeight <= 0 ||
                              parsedHeight > 300)) {
                        errors['height'] =
                            'Enter a height between 1 and 300 cm.';
                      }
                      if (targetText.isNotEmpty &&
                          (parsedTarget == null ||
                              !parsedTarget.isFinite ||
                              parsedTarget <= 0 ||
                              parsedTarget > 500)) {
                        errors['target'] =
                            'Enter a positive target weight below 500.';
                      }
                      if (parsedCal == null ||
                          parsedCal <= 0 ||
                          parsedCal > 15000) {
                        errors['calories'] =
                            'Enter a calorie target from 1 to 15000.';
                      }
                      for (final entry in {
                        'protein': parsedPro,
                        'carbs': parsedCar,
                        'fat': parsedFat,
                      }.entries) {
                        if (entry.value == null ||
                            entry.value! < 0 ||
                            entry.value! > 1000) {
                          errors[entry.key] =
                              'Enter a target from 0 to 1000 g.';
                        }
                      }
                      setState(() {
                        _fieldErrors
                          ..clear()
                          ..addAll(errors);
                      });
                      if (errors.isNotEmpty) return;
                      if (ref.read(accountGenerationProvider) !=
                              _accountGeneration ||
                          ref.read(accountTransitionProvider) ||
                          ref.read(accountHydratingProvider)) {
                        throw StateError(
                          'Account changed. Reopen Edit profile.',
                        );
                      }

                      double? finalTargetKg = parsedTarget;
                      if (finalTargetKg != null && !profile.useKg) {
                        finalTargetKg = finalTargetKg / 2.20462;
                      }

                      final updated = profile.copyWith(
                        name: nameController.text,
                        coachName: coachNameController.text.trim(),
                        height: parsedHeight,
                        clearHeight: heightText.isEmpty,
                        targetWeight: finalTargetKg,
                        clearTargetWeight: targetText.isEmpty,
                        currentWeight: _targetInputs?.weightKg,
                        age: _targetInputs?.age,
                        gender: _targetInputs?.gender,
                        activityLevel: _targetInputs?.activityLevel,
                        primaryGoal: _targetInputs?.goal,
                        targetCalories: parsedCal!,
                        targetProteinG: parsedPro!,
                        targetCarbsG: parsedCar!,
                        targetFatG: parsedFat!,
                        photoPath: _localPhotoPath,
                        clearPhoto: _clearPhoto,
                      );

                      await ref
                          .read(profileProvider.notifier)
                          .updateProfile(updated);

                      // The profile is already saved. Optional cleanup must not
                      // report that durable save as a failure or cross accounts.
                      if (mounted &&
                          _accountGeneration ==
                              ref.read(accountGenerationProvider) &&
                          (_clearPhoto ||
                              _localPhotoPath != profile.photoPath) &&
                          profile.photoPath != null &&
                          !profile.photoPath!.startsWith('assets/')) {
                        try {
                          final oldFile = File(
                            ref
                                .read(mediaRepoProvider)
                                .getAbsolutePath(profile.photoPath!),
                          );
                          if (await oldFile.exists()) await oldFile.delete();
                        } catch (_) {
                          // An unused avatar can be cleaned up on a later pass.
                        }
                      }

                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Could not save your profile. Your changes are still here; please try again.',
                            ),
                          ),
                        );
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/// Keeps avatar artwork visible while giving the whole circle native focus,
/// hover, and pressed feedback, plus a useful screen-reader action.
class _ProfileAvatarAction extends StatelessWidget {
  const _ProfileAvatarAction({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        button: true,
        child: Stack(
          children: [
            ExcludeSemantics(child: child),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.prefixIcon,
    this.keyboardType,
    this.onChanged,
    this.compact = false,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool compact;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.caption.copyWith(
            color: context.colors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: context.text.bodyStrong.copyWith(
            color: context.colors.textDark,
          ),
          decoration: InputDecoration(
            errorText: errorText,
            errorMaxLines: 3,
            filled: true,
            fillColor: context.colors.inputFill,
            prefixIcon: Icon(
              prefixIcon,
              size: compact ? 18 : 22,
              color: context.colors.primary,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 14 : 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiActivitySheet extends StatelessWidget {
  const _AiActivitySheet();
  @override
  Widget build(BuildContext context) {
    if (AiLogger.logs.isEmpty) {
      return AppSheet(
        title: 'Recent AI Activity',
        scrollable: true,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No AI requests made yet.'),
              const SizedBox(height: 16),
              Text(
                'Logs are kept locally on your device for diagnostic purposes (up to 20 recent requests).',
                style: context.text.caption.copyWith(
                  color:
                      Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return AppSheet(
      title: 'Recent AI Activity',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Logs are kept locally on your device for diagnostic purposes (up to 20 recent requests).',
              style: context.text.caption.copyWith(
                color:
                    Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AiLogger.logs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = AiLogger.logs[index];
              return ListTile(
                title: Text(
                  '${log.purpose} • ${log.model}',
                  style: context.text.body.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                subtitle: Text(
                  'Outcome: ${log.outcome}\n${log.timestamp.toString().substring(11, 16)}',
                  style: context.text.micro,
                ),
                trailing: Text(
                  '${log.durationMs} ms',
                  style: context.text.micro,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsTestSheet extends StatefulWidget {
  final WidgetRef ref;
  const _DiagnosticsTestSheet({required this.ref});
  @override
  State<_DiagnosticsTestSheet> createState() => _DiagnosticsTestSheetState();
}

class _DiagnosticsTestSheetState extends State<_DiagnosticsTestSheet> {
  final Map<String, Map<String, dynamic>> _results = {};
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _runTests() async {
    setState(() => _isTesting = true);
    final allModels = {
      ...AiClient.textModelsToTry,
      ...AiClient.visionModelsToTry,
    }.toList();
    final client = AiClient();
    final cred = widget.ref.read(credentialProvider);

    for (final model in allModels) {
      if (!mounted) break;
      final sw = Stopwatch()..start();
      try {
        await client.generateJson(
          prompt: '{"test":"Respond with exactly {"status":"ok"}"}',
          systemInstruction: 'Respond only in valid JSON.',
          apiKey: cred.key ?? '',
          skipCache: true,
        );
        sw.stop();
        if (mounted) {
          setState(() {
            _results[model] = {
              'status': 'âœ“',
              'latency': sw.elapsedMilliseconds,
              'error': null,
            };
          });
        }
      } catch (e) {
        sw.stop();
        final cause = (e is AiException) ? (e).cause : null;
        if (mounted) {
          setState(() {
            _results[model] = {
              'status': 'âœ—',
              'latency': sw.elapsedMilliseconds,
              'error': cause?.toString() ?? e.toString(),
            };
          });
        }
      }
    }
    if (mounted) setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'AI Connection Test',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_results.isEmpty && !_isTesting)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: _runTests,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run Diagnostic Test'),
              ),
            ),
          if (_isTesting) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          ..._results.entries.map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              color: Colors.transparent,
              child: Row(
                children: [
                  Text(
                    e.value['status'],
                    style: context.text.cardTitle.copyWith(
                      color: e.value['status'] == 'âœ“'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, style: context.text.body),
                        if (e.value['error'] != null)
                          Text(
                            e.value['error'],
                            style: context.text.micro.copyWith(
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text('${e.value['latency']} ms'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemDiagnosticsSheet extends ConsumerWidget {
  const _SystemDiagnosticsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(diagnosticLoggerProvider);
    final logs = logger.getLogs();

    return AppSheet(
      title: 'System Diagnostics',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${logs.length} logs in ring buffer',
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final sb = StringBuffer();
                        sb.writeln('=== Sthira Diagnostic Logs ===');
                        sb.writeln(
                          'Generated: ${DateTime.now().toIso8601String()}',
                        );
                        sb.writeln('==============================\n');
                        for (final log in logs) {
                          sb.writeln(
                            '[${log.level}] ${log.timestamp.toIso8601String()}',
                          );
                          sb.writeln(log.message);
                          if (log.error != null) {
                            sb.writeln('Error: ${log.error}');
                          }
                          if (log.stackTrace != null) {
                            sb.writeln('Stack: ${log.stackTrace}');
                          }
                          sb.writeln('---');
                        }
                        await Share.share(
                          sb.toString(),
                          subject: 'Sthira Diagnostics',
                        );
                      },
                      icon: const Icon(Icons.ios_share_rounded),
                      tooltip: 'Export Logs',
                      color: context.colors.primary,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Clear Diagnostics',
                              style: context.text.body,
                            ),
                            content: const Text(
                              'Are you sure? This will only clear your local diagnostic logs. It will not erase your actual app data or tracked habits.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  logger.clear();
                                  Navigator.pop(context); // close dialog
                                  Navigator.pop(context); // close sheet
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No diagnostic logs.')),
            )
          else
            ...logs.map((log) => _buildLogRow(context, log)),
        ],
      ),
    );
  }

  Widget _buildLogRow(BuildContext context, DiagnosticLog log) {
    Color lvlColor;
    switch (log.level) {
      case 'ERROR':
        lvlColor = context.colors.red;
        break;
      case 'WARN':
        lvlColor = context.colors.orange;
        break;
      default:
        lvlColor = context.colors.green;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: lvlColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.level,
                  style: context.text.micro.copyWith(color: lvlColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.timestamp.toString().substring(0, 19),
                  style: context.text.micro.copyWith(
                    color: context.colors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.message,
            style: context.text.caption.copyWith(
              color: context.colors.textDark,
            ),
          ),
          if (log.error != null) ...[
            const SizedBox(height: 4),
            Text(
              log.error!,
              style: context.text.micro.copyWith(color: context.colors.red),
            ),
          ],
        ],
      ),
    );
  }
}
