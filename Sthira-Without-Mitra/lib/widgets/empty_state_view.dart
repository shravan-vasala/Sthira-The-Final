import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.cardPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: context.colors.textMedium.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.cardTitle.copyWith(
              color: context.colors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.text.body.copyWith(color: context.colors.textMedium),
          ),
        ],
      ),
    );
  }
}
