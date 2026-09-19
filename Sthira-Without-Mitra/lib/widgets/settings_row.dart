import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.showChevron = true,
    this.trailing,
    this.leadingContent,
    this.backgroundColor,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leadingContent;
  final VoidCallback? onTap;
  final bool showChevron;
  final Widget? trailing;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.insetSurface,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.card),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.cardPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leadingContent != null)
                  leadingContent!
                else if (icon != null)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: context.colors.primary,
                        size: IconSize.row,
                      ),
                    ),
                  ),
                if (leadingContent != null || icon != null)
                  const SizedBox(width: Spacing.inline),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.bodyStrong.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: Spacing.textPair),
                        Text(
                          subtitle!,
                          style: context.text.caption.copyWith(
                            color: context.colors.textMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: Spacing.stack),
                  trailing!,
                ] else if (showChevron && onTap != null) ...[
                  const SizedBox(width: Spacing.stack),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textLight,
                    size: IconSize.inline,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
