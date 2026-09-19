import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../progress/widgets/shared_chart_card.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/exercise_log.dart';
import '../../models/exercise_pr.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  const ExerciseProgressScreen({super.key, required this.exerciseName});

  final String exerciseName;

  static const double kgToLbs = 2.20462;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(exerciseHistoryProvider(exerciseName));

    final profile = ref.watch(profileProvider);
    final useKg = profile.useKg;
    final unitLabel = useKg ? 'kg' : 'lb';
    final weightMultiplier = useKg ? 1.0 : kgToLbs;

    final plan = ref.watch(workoutPlanProvider);
    String displayTitle = exerciseName;
    if (plan != null) {
      for (final day in [
        ...plan.days,
        ...?plan.weeks?.expand((week) => week.days),
      ]) {
        for (final sec in day.sections) {
          for (final ex in sec.exercises) {
            if (ex.name == exerciseName) {
              displayTitle = ex.displayName ?? exerciseName;
              break;
            }
          }
        }
      }
    }

    // Sort logs by date to ensure proper charting
    final sortedLogs = logs.where((log) {
      final date = DateTime.tryParse(log.date);
      return date != null &&
          DateFormat('yyyy-MM-dd').format(date) == log.date &&
          log.sets.isNotEmpty &&
          log.sets.every(
            (set) =>
                ((set.reps ?? 0) > 0 || (set.durationSeconds ?? 0) > 0) &&
                (set.weight ?? 0).isFinite &&
                (set.weight ?? 0) >= 0,
          ) &&
          log.totalVolume.isFinite;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    // Aggregate logs by date to ensure one point per day
    final Map<String, double> dailyMaxWeight = {};
    final Map<String, double> dailyTotalVolume = {};
    final Map<String, double> dailyDuration = {};
    int malformedCount = logs.length - sortedLogs.length;

    for (var log in sortedLogs) {
      try {
        final parsedDate = DateTime.parse(log.date);
        final dateStr =
            "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";

        if (log.totalDurationSeconds > 0) {
          dailyDuration[dateStr] =
              (dailyDuration[dateStr] ?? 0) + log.totalDurationSeconds;
        }
        if (!log.sets.any((set) => (set.reps ?? 0) > 0)) continue;
        final weight = log.maxWeight * weightMultiplier;
        final vol = log.totalVolume * weightMultiplier;

        if (!weight.isFinite || !vol.isFinite) {
          malformedCount++;
          continue;
        }

        if (!dailyMaxWeight.containsKey(dateStr) ||
            weight > dailyMaxWeight[dateStr]!) {
          dailyMaxWeight[dateStr] = weight;
        }

        dailyTotalVolume[dateStr] = (dailyTotalVolume[dateStr] ?? 0.0) + vol;
      } catch (_) {
        malformedCount++;
      }
    }

    // Prepare Max Weight Data and Stats
    final List<ChartDataPoint> maxWeightData =
        dailyMaxWeight.entries
            .map((e) => ChartDataPoint(DateTime.parse(e.key), e.value))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    List<String> maxWeightStats = [];
    if (maxWeightData.isNotEmpty) {
      final weights = maxWeightData.map((d) => d.value ?? 0.0).toList();
      final max = weights.reduce((a, b) => a > b ? a : b);
      final last = weights.last;
      final avg = weights.reduce((a, b) => a + b) / weights.length;
      maxWeightStats = [
        '${max.toStringAsFixed(1)} $unitLabel',
        '${last.toStringAsFixed(1)} $unitLabel',
        '${avg.toStringAsFixed(1)} $unitLabel',
      ];
    }

    // Prepare Total Volume Data and Stats
    final List<ChartDataPoint> totalVolumeData =
        dailyTotalVolume.entries
            .map((e) => ChartDataPoint(DateTime.parse(e.key), e.value))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    List<String> totalVolumeStats = [];
    if (totalVolumeData.isNotEmpty) {
      final vols = totalVolumeData.map((d) => d.value ?? 0.0).toList();
      final max = vols.reduce((a, b) => a > b ? a : b);
      final last = vols.last;
      final avg = vols.reduce((a, b) => a + b) / vols.length;
      totalVolumeStats = [
        '${max.toStringAsFixed(1)} $unitLabel',
        '${last.toStringAsFixed(1)} $unitLabel',
        '${avg.toStringAsFixed(1)} $unitLabel',
      ];
    }

    final startDate = sortedLogs.isNotEmpty
        ? DateTime.parse(sortedLogs.first.date)
        : DateTime.now();
    final endDate = DateTime.now();

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: Text(displayTitle),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: sortedLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 64,
                    color: context.colors.textLight.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    logs.isEmpty
                        ? 'No data logged yet'
                        : 'No valid logs to display',
                    style: context.text.bodyStrong.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    logs.isEmpty
                        ? 'Log exercise data to see your progress'
                        : 'Older invalid records were excluded.',
                    style: context.text.caption.copyWith(
                      color: context.colors.textLight,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.screen,
                vertical: Spacing.section,
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      if (ref
                              .watch(exerciseLogRepoProvider)
                              .getPr(exerciseName) !=
                          null) ...[
                        _PrSummary(
                          pr: ref
                              .watch(exerciseLogRepoProvider)
                              .getPr(exerciseName)!,
                          unitLabel: unitLabel,
                          weightMultiplier: weightMultiplier,
                        ),
                        const SizedBox(height: Spacing.stack),
                      ],
                      if (dailyDuration.isNotEmpty) ...[
                        SharedChartCard(
                          metric: const MetricSpec(
                            title: 'Time completed',
                            unit: 's',
                            isCount: true,
                          ),
                          data: dailyDuration.entries
                              .map(
                                (entry) => ChartDataPoint(
                                  DateTime.parse(entry.key),
                                  entry.value,
                                ),
                              )
                              .toList(),
                          statLabels: const ['TOTAL', 'LAST'],
                          statValues: [
                            '${dailyDuration.values.reduce((a, b) => a + b).round()} s',
                            '${dailyDuration.values.last.round()} s',
                          ],
                          timeFormat: ChartTimeFormat.allTime,
                          startDate: startDate,
                          endDate: endDate,
                          emptyMessage: 'No time logged yet',
                        ),
                        const SizedBox(height: Spacing.stack),
                      ],
                      if (maxWeightData.isNotEmpty)
                        SharedChartCard(
                          metric: MetricSpec(
                            title: 'Max Weight',
                            unit: unitLabel,
                            isCount: false,
                          ),
                          data: maxWeightData,
                          statLabels: const ['BEST', 'LAST', 'AVERAGE'],
                          statValues: maxWeightStats,
                          timeFormat: ChartTimeFormat.allTime,
                          startDate: startDate,
                          endDate: endDate,
                          emptyMessage: 'No data logged yet',
                        ),
                      const SizedBox(height: Spacing.stack),
                      if (totalVolumeData.isNotEmpty)
                        SharedChartCard(
                          metric: MetricSpec(
                            title: 'Total Volume',
                            unit: '$unitLabel (load×reps)',
                            isCount: false,
                          ),
                          data: totalVolumeData,
                          statLabels: const ['BEST', 'LAST', 'AVERAGE'],
                          statValues: totalVolumeStats,
                          timeFormat: ChartTimeFormat.allTime,
                          startDate: startDate,
                          endDate: endDate,
                          emptyMessage: 'No data logged yet',
                        ),
                      const SizedBox(height: Spacing.stack),
                      if (malformedCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Skipped $malformedCount malformed historic logs to keep charts accurate.',
                            style: context.text.caption.copyWith(
                              color: context.colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.stack),
                      ],
                      Text(
                        'HISTORY',
                        style: context.text.eyebrow.copyWith(
                          color: context.colors.textLight,
                        ),
                      ),

                      const SizedBox(height: Spacing.stack),
                    ]),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _HistoryCard(
                        log: sortedLogs[sortedLogs.length - 1 - index],
                        unitLabel: unitLabel,
                        weightMultiplier: weightMultiplier,
                      );
                    }, childCount: sortedLogs.length),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PrSummary extends StatelessWidget {
  final ExercisePr pr;
  final String unitLabel;
  final double weightMultiplier;
  const _PrSummary({
    required this.pr,
    required this.unitLabel,
    required this.weightMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadTight),
      decoration: BoxDecoration(
        color: context.colors.goldMuted,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: context.colors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PERSONAL RECORDS',
                  style: context.text.eyebrow.copyWith(
                    color: context.colors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.stack),
          if (pr.maxWeight > 0)
            _buildPrRow(
              'Max Weight',
              '${(pr.maxWeight * weightMultiplier).toStringAsFixed(1)}$unitLabel × ${pr.maxWeightReps}',
              context,
            )
          else if (pr.maxReps > 0)
            _buildPrRow(
              'Max Weight',
              'Bodyweight × ${pr.maxWeightReps}',
              context,
            ),
          if (pr.maxReps > 0 &&
              (pr.maxWeight == 0 || pr.maxReps > pr.maxWeightReps))
            _buildPrRow(
              'Max Reps',
              '${pr.maxReps} reps @ ${pr.maxRepsWeight > 0 ? (pr.maxRepsWeight * weightMultiplier).toStringAsFixed(1) + unitLabel : "BW"}',
              context,
            ),
          if (pr.estimated1RM > 0)
            _buildPrRow(
              'Est. 1RM',
              '${(pr.estimated1RM * weightMultiplier).toStringAsFixed(1)}$unitLabel',
              context,
            ),
          if (pr.maxVolume > 0)
            _buildPrRow(
              'Max Volume',
              '${(pr.maxVolume * weightMultiplier).toStringAsFixed(1)}$unitLabel',
              context,
            ),
        ],
      ),
    );
  }

  Widget _buildPrRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.inline),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final caption = Text(
            label,
            style: context.text.body.copyWith(color: context.colors.textMedium),
          );
          final metric = Text(
            value,
            style: context.text.body.copyWith(color: context.colors.textDark),
          );
          if (constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [caption, metric],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: caption),
              const SizedBox(width: Spacing.stack),
              Flexible(child: metric),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.log,
    required this.unitLabel,
    required this.weightMultiplier,
  });

  final ExerciseLog log;
  final String unitLabel;
  final double weightMultiplier;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'dd MMM yyyy',
    ).format(DateTime.parse(log.date));
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.inline),
      padding: const EdgeInsets.all(Spacing.cardPadTight),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: context.text.body.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.sets
                      .map((s) {
                        if ((s.durationSeconds ?? 0) > 0)
                          return '${s.durationSeconds} s';
                        final w = s.weight ?? 0.0;
                        if (w > 0) {
                          final strWeight =
                              (w * weightMultiplier) ==
                                  (w * weightMultiplier).toInt()
                              ? (w * weightMultiplier).toInt().toString()
                              : (w * weightMultiplier).toStringAsFixed(1);
                          return '${s.reps}×$strWeight$unitLabel';
                        }
                        return '${s.reps}×BW';
                      })
                      .join(' | '),
                  style: context.text.micro.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.stack),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  log.totalDurationSeconds > 0
                      ? '${log.totalDurationSeconds} s'
                      : '${(log.totalVolume * weightMultiplier).toStringAsFixed(0)} $unitLabel',
                  style: context.text.bodyStrong.copyWith(
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(height: Spacing.textPair),
                Text(
                  'load × reps',
                  style: context.text.micro.copyWith(
                    color: context.colors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
