import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool centerText;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final int? minLines;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = '',
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.centerText = false,
    this.onChanged,
    this.focusNode,
    this.minLines,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labelText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              bottom: Spacing.inline,
              left: Gap.x4,
            ),
            child: Text(
              labelText,
              style: context.text.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.textMedium,
              ),
            ),
          ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          obscureText: obscureText,
          textAlign: centerText ? TextAlign.center : TextAlign.left,
          minLines: minLines,
          maxLines: obscureText ? 1 : maxLines,
          style: context.text.bodyStrong.copyWith(
            color: context.colors.textDark,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.text.body.copyWith(
              color: context.colors.textLight,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: context.colors.textMedium)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: context.colors.inputFill,
          ),
        ),
      ],
    );
  }
}
