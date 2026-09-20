import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/insight.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/insights_provider.dart';
import '../../../widgets/surface_card.dart';
import '../../../theme/app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class DailyInsightCard extends ConsumerWidget {
  const DailyInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    // The provider orders supported insights by evidence freshness and relevance.
    final insight = insights.first;

    final (bgColor, iconColor) = switch (insight.severity) {
      InsightSeverity.positive => (
        context.colors.green.withValues(alpha: 0.1),
        context.colors.green,
      ),
      InsightSeverity.warning => (
        context.colors.orange.withValues(alpha: 0.1),
        context.colors.orange,
      ),
      InsightSeverity.neutral => (
        context.colors.primary.withValues(alpha: 0.1),
        context.colors.primary,
      ),
    };

    return SurfaceCard(
          margin: const EdgeInsets.symmetric(horizontal: Spacing.screen),
          color: context.colors.card,
          border: null, // Sthira: No borders!
          padding: const EdgeInsets.all(Spacing.cardPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Icon(insight.icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: Spacing.inline),
                  Expanded(
                    child: Text(
                      'RECENT INSIGHT',
                      style: context.text.micro.copyWith(
                        color: context.colors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.stack),
              Text(
                insight.title,
                style: context.text.cardTitle.copyWith(
                  color: context.colors.textDark,
                ),
              ),
              const SizedBox(height: Gap.x4),
              Text(
                insight.description,
                style: insight.supportingText == null
                    ? context.text.caption.copyWith(
                        color: context.colors.textMedium,
                      )
                    : context.text.bodyStrong,
              ),
              if (insight.supportingText case final supportingText?) ...[
                const SizedBox(height: Gap.x4),
                Text(supportingText, style: context.text.caption),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: Motion.deliberate, curve: Motion.enter)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: Motion.deliberate,
          curve: Motion.enter,
        );
  }
}
