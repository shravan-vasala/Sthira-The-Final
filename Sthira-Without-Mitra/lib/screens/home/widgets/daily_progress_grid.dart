import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_insets.dart';
import '../../../providers/app_providers.dart';
import '../../../services/health_connect_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../weight_entry_dialog.dart';
import '../steps_entry_dialog.dart';
import 'sync_status_sheet.dart';
import '../../../widgets/surface_card.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class DailyProgressGrid extends ConsumerWidget {
  const DailyProgressGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches:
    // - dailyLogProvider.select((l) => l.weight)
    final weight = ref.watch(dailyLogProvider.select((l) => l.weight));
    final useKg = ref.watch(profileProvider.select((p) => p.useKg));
    String formatWeight(double kg) =>
        '${(useKg ? kg : kg * 2.20462).toStringAsFixed(1)} ${useKg ? 'kg' : 'lb'}';

    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final isFuture = selectedDate.isAfter(today);
    final isToday = selectedDate.isAtSameMomentAs(today);

    String weightSubtitle;
    if (weight != null) {
      weightSubtitle = formatWeight(weight);
    } else if (isFuture) {
      weightSubtitle = 'No data';
    } else {
      final weightData = _lastLoggedWeight(ref, selectedDateStr);
      weightSubtitle = weightData != null
          ? 'Last: ${formatWeight(weightData.weight)} (${DateFormat('MMM d').format(weightData.date)})'
          : 'Tap to log';
    }

    final mediaRepo = ref.watch(mediaRepoProvider);
    final allPhotos = mediaRepo.getAllProgressPhotos();
    final flattenedPhotos = allPhotos.expand((e) => e.value).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kScreenPadding),
      child: Column(
        children: [
          _ProgressCard(
            title: 'Body Stats',
            icon: Icons.straighten_rounded,
            iconColor: context.colors.primary,
            subtitle: 'Tap to view',
            onTap: () => context.go('/home/body-stats'),
          ),
          const SizedBox(height: Spacing.stack),
          _ProgressCard(
            title: 'Physique',
            icon: Icons.camera_alt_rounded,
            iconColor: context.colors.orange,
            subtitle: 'Progress',
            thumbnails: flattenedPhotos,
            onTap: () => context.go('/home/physique-pictures'),
          ),
          const SizedBox(height: Spacing.stack),
          _ProgressCard(
            title: 'Body Weight',
            icon: Icons.monitor_weight_rounded,
            iconColor: context.colors.indigo,
            subtitle: weightSubtitle,
            onTap: isFuture
                ? null
                : () {
                    showAppBottomSheet(
                      context: context,
                      builder: (_) => const WeightEntryDialog(),
                    );
                  },
            onChartTap: () => context.push('/progress?metric=weight'),
          ),
          const SizedBox(height: Spacing.stack),
          _StepsCard(isFuture: isFuture, isToday: isToday),
        ],
      ),
    );
  }

  ({double weight, DateTime date})? _lastLoggedWeight(
    WidgetRef ref,
    String beforeOrOnDate,
  ) {
    final repo = ref.read(dailyLogRepoProvider);
    final end = DateTime.parse(beforeOrOnDate);
    final start = end.subtract(const Duration(days: 90));
    final startStr =
        '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final logs = repo.getLogsInRange(startStr, beforeOrOnDate);
    for (int i = logs.length - 1; i >= 0; i--) {
      final w = logs[i].weight;
      if (w != null) {
        final date = DateTime.parse(logs[i].date);
        return (weight: w, date: date);
      }
    }
    return null;
  }
}

/// Special Steps card that handles the Health Connect first-run CTA.
class _StepsCard extends ConsumerStatefulWidget {
  const _StepsCard({required this.isFuture, required this.isToday});

  final bool isFuture;
  final bool isToday;

  @override
  ConsumerState<_StepsCard> createState() => _StepsCardState();
}

class _StepsCardState extends ConsumerState<_StepsCard> {
  bool _showSyncCta = false;
  bool _checkingPermission = true;
  bool _isAuth = false;

  @override
  void initState() {
    super.initState();
    _checkHealthConnectStatus();
  }

  Future<void> _checkHealthConnectStatus() async {
    final hcService = ref.read(healthConnectServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    // Simply query Health Connect if authorization exists.
    // Relying organically on healthConnect stepsSource in the UI.
    var connected = await hcService.canReadSteps();
    if (!connected) {
      connected = await hcService.isAuthorized();
      // Even if authorized, if we can't read steps and it's today, we might need a sync or we might have lost permission.
      // We will let 'connected' be the definitive source of truth to avoid hiding Connect forever.
    }

    if (mounted) {
      setState(() {
        _isAuth = connected;
        _showSyncCta = !connected && widget.isToday;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _handleSyncTap() async {
    final hcService = ref.read(healthConnectServiceProvider);
    final generation = ref.read(accountGenerationProvider);

    // Check if Health Connect is installed
    final available = await hcService.isAvailable();
    if (!available) {
      // Deep link to Play Store
      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Request permission
    final granted = await hcService.requestPermission();
    if (!granted) return;

    if (!mounted || generation != ref.read(accountGenerationProvider)) return;
    await ref.read(syncControllerProvider.notifier).sync(isManualRefresh: true);
    if (!mounted || generation != ref.read(accountGenerationProvider)) return;
    await _checkHealthConnectStatus();
  }

  @override
  Widget build(BuildContext context) {
    final steps = ref.watch(dailyLogProvider.select((l) => l.steps));
    final stepsSource = ref.watch(
      dailyLogProvider.select((l) => l.stepsSource),
    );

    // Hide Sync CTA once we have Health Connect data (covers race with async permission check)
    final showSyncCta =
        _showSyncCta &&
        !_checkingPermission &&
        !(steps != null && stepsSource == 'healthConnect');

    String stepsSubtitle;
    String? sourceHint;

    if (_checkingPermission) {
      stepsSubtitle = 'Checking sync...';
    } else if (steps != null) {
      stepsSubtitle = '${NumberFormat.decimalPattern().format(steps)} steps';
      if (stepsSource == 'healthConnect') {
        sourceHint = 'Synced';
      } else if (stepsSource == 'manual') {
        sourceHint = 'Manual';
      }
    } else {
      stepsSubtitle = widget.isFuture ? 'No data' : 'Tap to log';
      if (_isAuth) {
        sourceHint = 'Connected';
      } else if (showSyncCta) {
        sourceHint = 'HC/Manual';
      }
    }

    return SurfaceCard(
      margin: EdgeInsets.zero,
      onTap: widget.isFuture
          ? null
          : () {
              if (_isAuth) {
                showAppBottomSheet(
                  context: context,
                  isScrollControlled: false,
                  builder: (_) => const SyncStatusSheet(),
                );
              } else {
                showAppBottomSheet(
                  context: context,
                  builder: (_) => const StepsEntryDialog(),
                );
              }
            },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Icon(
              Icons.directions_walk_rounded,
              size: 20,
              color: context.colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps',
                  style: context.text.cardTitle.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (steps != null)
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: steps),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : Motion.deliberate,
                        curve: Motion.enter,
                        builder: (context, val, child) {
                          return Text(
                            '${NumberFormat.decimalPattern().format(val)} steps',
                            style: context.text.caption.copyWith(
                              color: context.colors.textMedium,
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        stepsSubtitle,
                        style: context.text.caption.copyWith(
                          color: context.colors.textMedium,
                        ),
                      ),
                    if (sourceHint != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (sourceHint == 'Synced' ||
                                  sourceHint == 'Connected')
                              ? context.colors.green.withValues(alpha: 0.1)
                              : context.colors.border,
                          borderRadius: BorderRadius.circular(Radii.micro),
                        ),
                        child: Text(
                          sourceHint,
                          style: context.text.micro.copyWith(
                            color:
                                (sourceHint == 'Synced' ||
                                    sourceHint == 'Connected')
                                ? context.colors.green
                                : context.colors.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_checkingPermission)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.primary,
                ),
              ),
            )
          else if (showSyncCta)
            GestureDetector(
              onTap: _handleSyncTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connect',
                  style: context.text.caption.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
            )
          else ...[
            if (steps != null) ...[
              GestureDetector(
                onTap: () => context.push('/progress?metric=steps'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 48,
                  width: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.show_chart_rounded,
                    size: 22,
                    color: context.colors.textMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (!widget.isFuture)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: context.colors.textMedium.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    this.onTap,
    this.thumbnails,
    this.onChartTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final VoidCallback? onTap;
  final List<String>? thumbnails;
  final VoidCallback? onChartTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String displaySubtitle = subtitle;
    if (subtitle.contains(' Tap to log') ||
        subtitle == 'Tap to log' ||
        subtitle == 'Tap to view' ||
        subtitle == 'Progress photos' ||
        subtitle == 'Progress' ||
        subtitle == 'No data') {
      displaySubtitle = subtitle == 'No data'
          ? 'No data yet'
          : subtitle.replaceAll('--', '').trim();
    } else if (subtitle.contains('Last:')) {
      displaySubtitle = subtitle;
    }

    return SurfaceCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.cardTitle.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
                const SizedBox(height: Gap.x4),
                Text(
                  displaySubtitle,
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          if (thumbnails != null && thumbnails!.isNotEmpty)
            Row(
              children: [
                ...thumbnails!
                    .take(3)
                    .map(
                      (path) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.micro),
                          child: kIsWeb
                              ? Image.network(
                                  path,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(
                                    ref
                                        .read(mediaRepoProvider)
                                        .getAbsolutePath(path),
                                  ),
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  cacheWidth: 108,
                                  cacheHeight: 108,
                                ),
                        ),
                      ),
                    ),
                if (thumbnails!.length > 3)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Radii.micro),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+${thumbnails!.length - 3}',
                      style: context.text.micro.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: context.colors.textMedium.withValues(alpha: 0.5),
                  ),
              ],
            )
          else ...[
            if (onChartTap != null &&
                displaySubtitle != 'Tap to log' &&
                displaySubtitle != 'Tap to view' &&
                displaySubtitle != 'No data yet') ...[
              GestureDetector(
                onTap: onChartTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 48,
                  width: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.show_chart_rounded,
                    size: 22,
                    color: context.colors.textMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: context.colors.textMedium.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}
