import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

/// Consistent modal bottom sheets that clear the floating shell nav.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? Colors.transparent,
    builder: builder,
  );
}

/// Shared sheet chrome: handle, padding, optional title/subtitle, keyboard inset.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.maxHeightFactor = 0.9,
    this.scrollable = true,
    this.draggable = false,
    this.titleAction,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final double maxHeightFactor;
  final bool scrollable;
  final bool draggable;
  final Widget? titleAction;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(Radii.micro),
            ),
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: 20),
          Text(
            title!,
            style: context.text.screenTitle.copyWith(
              color: context.colors.textDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: Spacing.inline),
            Text(
              subtitle!,
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ],
          if (titleAction != null) ...[
            const SizedBox(height: Spacing.inline),
            Align(alignment: Alignment.centerRight, child: titleAction),
          ],
          const SizedBox(height: 20),
        ] else
          const SizedBox(height: 20),
        if (draggable)
          Expanded(child: child)
        else if (scrollable)
          Flexible(child: SingleChildScrollView(child: child))
        else
          child,
      ],
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: draggable
                  ? null
                  : BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height * maxHeightFactor,
                    ),
              decoration: BoxDecoration(
                color: context.colors.card.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Radii.sheet),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                Spacing.sheetPadH,
                Gap.x16,
                Spacing.sheetPadH,
                Spacing.section,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
