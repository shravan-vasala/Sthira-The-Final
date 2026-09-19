import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class AsyncErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? actionText;
  final IconData icon;

  const AsyncErrorCard({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
    this.actionText,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: context.colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: context.text.body.copyWith(color: context.colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: context.text.body.copyWith(color: context.colors.textDark),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionText ?? 'Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
