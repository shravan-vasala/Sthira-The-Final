import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../services/health_connect_service.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../steps_entry_dialog.dart';
import '../../../widgets/async_error_card.dart';
import '../../../widgets/primary_button.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class SyncStatusSheet extends ConsumerStatefulWidget {
  const SyncStatusSheet({super.key});

  @override
  ConsumerState<SyncStatusSheet> createState() => _SyncStatusSheetState();
}

class _SyncStatusSheetState extends ConsumerState<SyncStatusSheet> {
  String? _errorMessage;
  String? _errorAction;

  bool _checking = true;
  bool _authorized = false;
  bool _isAvailable = false;
  String? _lastAttempt;
  String? _lastSuccess;
  bool _backfillDone = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final hcService = ref.read(healthConnectServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    final avail = await hcService.isAvailable();
    final auth = await hcService.isAuthorized();
    if (!mounted) return;
    final account = ref.read(activeAccountIdProvider);
    final attemptStr = prefs.getString('health_${account}_last_attempt');
    final successStr = prefs.getString('health_${account}_today_sync');

    if (mounted) {
      setState(() {
        _isAvailable = avail;
        _authorized = auth;
        _lastAttempt = attemptStr;
        _lastSuccess = successStr;
        _backfillDone = hcService.isBackfillDone;
        _checking = false;
      });
    }
  }

  String _formatTime(String? isoStr) {
    if (isoStr == null) return 'Never';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyLog = ref.watch(dailyLogProvider);
    final steps = dailyLog.steps ?? 0;
    final source = ref.watch(stepsSourceProvider);
    final pendingCount = ref.watch(syncPendingCountProvider).value ?? 0;

    String sourceText = 'Unknown';
    if (source == StepsSource.healthConnect) {
      sourceText = 'Health Connect';
    } else if (source == StepsSource.manual) {
      sourceText = 'Manual Entry';
    } else {
      sourceText = 'None';
    }

    return AppSheet(
      title: 'Sync Status',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pendingCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    color: context.colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$pendingCount items pending cloud sync',
                      style: context.text.body.copyWith(
                        color: context.colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Total Steps display
          Center(
            child: Column(
              children: [
                Text(
                  '$steps',
                  style: AppTheme.numeric(
                    context.text.metric.copyWith(color: context.colors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Steps Today',
                  style: context.text.bodyStrong.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Diagnostics
          Text('DIAGNOSTICS', style: context.text.eyebrow),
          const SizedBox(height: Spacing.block),

          if (_checking)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _DiagnosticRow(label: 'Source', value: sourceText),
            _DiagnosticRow(
              label: 'Permissions',
              value: _isAvailable
                  ? (_authorized ? 'Granted' : 'Missing/Denied')
                  : 'Unavailable',
            ),
            _DiagnosticRow(
              label: 'Last Successful Read',
              value: _formatTime(_lastSuccess),
            ),
            _DiagnosticRow(
              label: 'Last Attempted Read',
              value: _formatTime(_lastAttempt),
            ),
            _DiagnosticRow(
              label: '90-Day Backfill',
              value: _backfillDone ? 'Complete' : 'Pending',
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            AsyncErrorCard(
              title: 'Sync Failed',
              message: _errorMessage!,
              actionText: _errorAction,
              onRetry: _errorAction != null
                  ? () async {
                      final hcService = ref.read(healthConnectServiceProvider);
                      if (_errorAction == 'Install Health Connect') {
                        setState(
                          () => _errorMessage =
                              'Please install Health Connect from the Play Store.',
                        );
                      } else if (_errorAction == 'Grant Permission') {
                        await hcService.requestPermission();
                        await _loadStatus();
                        if (mounted) setState(() => _errorMessage = null);
                      }
                    }
                  : null,
            ),
          ],

          const SizedBox(height: Spacing.section),
          PrimaryButton(
            label: 'Refresh Now',
            isLoading: _checking,
            onPressed: () async {
              setState(() {
                _errorMessage = null;
                _checking = true;
              });

              final hcService = ref.read(healthConnectServiceProvider);
              final prefs = ref.read(sharedPreferencesProvider);
              final selectedDate = ref.read(dateStringProvider);

              try {
                final isAvail = await hcService.isAvailable();
                if (!mounted) return;
                if (!isAvail) {
                  setState(() {
                    _errorMessage =
                        'Health Connect is not available on this device.';
                    _errorAction = 'Install Health Connect';
                    _checking = false;
                  });
                  return;
                }

                await prefs.setString(
                  'health_${ref.read(activeAccountIdProvider)}_last_attempt',
                  DateTime.now().toIso8601String(),
                );

                var canSync = await hcService.isAuthorized();
                if (!canSync) {
                  canSync = await hcService.canReadSteps();
                }

                if (!mounted) return;
                if (!canSync) {
                  setState(() {
                    _errorMessage = 'Missing permissions to read steps.';
                    _errorAction = 'Grant Permission';
                    _checking = false;
                  });
                  await _loadStatus();
                  return;
                }

                await ref
                    .read(syncControllerProvider.notifier)
                    .sync(
                      isManualRefresh: true,
                      explicitTargetDate: selectedDate,
                    );

                if (!mounted) return;
                final failure = ref.read(healthSyncErrorProvider);
                if (failure != null) {
                  setState(() {
                    _errorMessage = failure;
                    _errorAction = null;
                    _checking = false;
                  });
                  return;
                }
                Navigator.of(context).pop();
              } catch (e) {
                if (!mounted) return;
                setState(() {
                  _errorMessage = 'An unexpected error occurred during sync.';
                  _errorAction = null;
                  _checking = false;
                });
                await _loadStatus();
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                showAppBottomSheet(
                  context: context,
                  builder: (_) => const StepsEntryDialog(),
                );
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Log Manually Instead',
                style: context.text.bodyStrong.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagnosticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.text.body.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.text.body.copyWith(color: context.colors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
