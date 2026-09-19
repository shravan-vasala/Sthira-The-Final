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
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../weight_entry_dialog.dart';
import '../steps_entry_dialog.dart';
import 'sync_status_sheet.dart';
import '../../../widgets/surface_card.dart';
import '../../../theme/app_typography.dart';
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
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
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
  bool _checkingPermission = true;
  bool _isAuth = false;

  @override
  void initState() {
    super.initState();
    _checkHealthConnectStatus();
  }

  Future<void> _checkHealthConnectStatus() async {
    final hcService = ref.read(healthConnectServiceProvider);
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
        widget.isToday &&
        !_isAuth &&
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
      child: _ProgressContent(
        title: 'Steps',
        icon: Icons.directions_walk_rounded,
        iconColor: context.colors.green,
        navigable: !widget.isFuture,
        roomyAction: showSyncCta,
        details: Wrap(
          spacing: Spacing.inline,
          runSpacing: Spacing.inline,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (steps != null)
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: steps),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Motion.deliberate,
                curve: Motion.enter,
                builder: (context, value, child) => Text(
                  '${NumberFormat.decimalPattern().format(value)} steps',
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              )
            else
              Text(
                stepsSubtitle,
                style: context.text.caption.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            if (sourceHint != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.inline,
                  vertical: Gap.x2,
                ),
                decoration: BoxDecoration(
                  color: (sourceHint == 'Synced' || sourceHint == 'Connected')
                      ? context.colors.green.withValues(alpha: 0.1)
                      : context.colors.border,
                  borderRadius: BorderRadius.circular(Radii.micro),
                ),
                child: Text(
                  sourceHint,
                  style: context.text.micro.copyWith(
                    color: (sourceHint == 'Synced' || sourceHint == 'Connected')
                        ? context.colors.green
                        : context.colors.textMedium,
                  ),
                ),
              ),
          ],
        ),
        action: _checkingPermission
            ? SizedBox(
                width: IconSize.inline,
                height: IconSize.inline,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.primary,
                ),
              )
            : showSyncCta
            ? TextButton(
                onPressed: _handleSyncTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: context.colors.primary.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: context.colors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.stack,
                    vertical: Spacing.inline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  textStyle: context.text.caption,
                ),
                child: const Text('Connect'),
              )
            : steps != null
            ? _ChartAction(
                tooltip: 'View steps progress',
                onPressed: () => context.push('/progress?metric=steps'),
              )
            : null,
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

    final photos = thumbnails ?? const <String>[];
    if (photos.isNotEmpty) {
      displaySubtitle =
          '${photos.length} progress ${photos.length == 1 ? 'photo' : 'photos'}';
    }
    final showChart =
        onChartTap != null &&
        displaySubtitle != 'Tap to log' &&
        displaySubtitle != 'Tap to view' &&
        displaySubtitle != 'No data yet';

    return SurfaceCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
          final previewCount =
              constraints.maxWidth < 280 ||
                  largeText ||
                  constraints.maxWidth >= 360
              ? 2
              : 1;
          return _ProgressContent(
            title: title,
            icon: icon,
            iconColor: iconColor,
            navigable: onTap != null,
            roomyAction: photos.isNotEmpty,
            details: Text(
              displaySubtitle,
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            action: photos.isNotEmpty
                ? _PhotoPreviews(
                    photos: photos,
                    previewCount: previewCount,
                    absolutePath: ref.read(mediaRepoProvider).getAbsolutePath,
                  )
                : showChart
                ? _ChartAction(
                    tooltip: 'View weight progress',
                    onPressed: onChartTap!,
                  )
                : null,
          );
        },
      ),
    );
  }
}

/// Keeps the familiar icon and typography while giving large text and secondary
/// actions room to wrap instead of squeezing the title.
class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.details,
    required this.navigable,
    this.action,
    this.roomyAction = false,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget details;
  final bool navigable;
  final Widget? action;
  final bool roomyAction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final actionBelow =
          action != null &&
          (largeText || (roomyAction && constraints.maxWidth < 280));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.stack),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
                child: Icon(icon, size: IconSize.row, color: iconColor),
              ),
              const SizedBox(width: Spacing.block),
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
                    if (!largeText) ...[
                      const SizedBox(height: Spacing.textPair),
                      details,
                    ],
                  ],
                ),
              ),
              if (action != null && !actionBelow) ...[
                const SizedBox(width: Spacing.inline),
                action!,
              ],
              if (navigable) ...[
                const SizedBox(width: Spacing.inline),
                Icon(
                  Icons.chevron_right_rounded,
                  size: IconSize.inline,
                  color: context.colors.textMedium.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
          if (largeText) ...[const SizedBox(height: Spacing.inline), details],
          if (actionBelow) ...[
            const SizedBox(height: Spacing.stack),
            Align(alignment: Alignment.centerRight, child: action!),
          ],
        ],
      );
    },
  );
}

class _ChartAction extends StatelessWidget {
  const _ChartAction({required this.tooltip, required this.onPressed});
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    onPressed: onPressed,
    icon: Icon(
      Icons.show_chart_rounded,
      size: IconSize.row,
      color: context.colors.textMedium,
    ),
  );
}

class _PhotoPreviews extends StatelessWidget {
  const _PhotoPreviews({
    required this.photos,
    required this.previewCount,
    required this.absolutePath,
  });
  final List<String> photos;
  final int previewCount;
  final String Function(String) absolutePath;

  @override
  Widget build(BuildContext context) {
    final shown = photos.take(previewCount).toList();
    // The photo count is already announced by the tile subtitle.
    return ExcludeSemantics(
      child: Wrap(
        spacing: Spacing.textPair,
        runSpacing: Spacing.inline,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final path in shown)
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.micro),
              child: SizedBox(
                width: 36,
                height: 36,
                child: kIsWeb
                    ? Image.network(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: _missingPhoto,
                      )
                    : Image.file(
                        File(absolutePath(path)),
                        fit: BoxFit.cover,
                        cacheWidth: 108,
                        cacheHeight: 108,
                        errorBuilder: _missingPhoto,
                      ),
              ),
            ),
          if (photos.length > shown.length)
            Container(
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(Spacing.inline),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.micro),
              ),
              child: Text(
                '+${photos.length - shown.length}',
                style: context.text.micro.copyWith(
                  color: context.colors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _missingPhoto(BuildContext context, Object error, StackTrace? stack) =>
      ColoredBox(
        color: context.colors.border,
        child: Icon(
          Icons.photo_outlined,
          size: IconSize.row,
          color: context.colors.textMedium,
        ),
      );
}
