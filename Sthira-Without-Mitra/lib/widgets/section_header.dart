import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Main section label used on Home / Workout / similar lists.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.icon,
    this.trailing,
    this.countLabel,
    this.horizontalPadding = Spacing.screen,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Widget? countLabel;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: context.colors.primary, size: IconSize.inline),
            const SizedBox(width: Spacing.inline),
          ],
          Expanded(
            child: Wrap(
              spacing: Spacing.inline,
              runSpacing: Spacing.textPair,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.text.sectionLabel),
                ),
                if (countLabel != null) countLabel!,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Spacing.inline),
            IconButtonTheme(
              data: IconButtonThemeData(
                style: IconButton.styleFrom(
                  iconSize: IconSize.inline,
                  foregroundColor: context.colors.accentText,
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
              child: IconTheme.merge(
                data: IconThemeData(
                  size: IconSize.inline,
                  color: context.colors.accentText,
                ),
                child: trailing!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
