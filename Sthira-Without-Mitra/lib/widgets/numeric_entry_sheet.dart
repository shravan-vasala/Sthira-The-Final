import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/layout_insets.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import 'app_bottom_sheet.dart';
import 'primary_button.dart';

class NumericEntrySheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String suffixText;
  final String? hintText;
  final String? errorText;
  final String saveLabel;
  final IconData? saveIcon;
  final FutureOr<void> Function()? onSave;
  final FutureOr<void> Function()? onClear;
  final TextEditingController? controller;
  final Widget Function(BuildContext, TextEditingController?)?
  extraContentBuilder;
  final Widget Function(BuildContext)? topExtraContentBuilder;
  final Widget Function(BuildContext)? bottomExtraContentBuilder;
  final Widget? customField; // Used for Timer countdown
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const NumericEntrySheet({
    super.key,
    required this.title,
    this.subtitle,
    this.suffixText = '',
    this.hintText,
    this.errorText,
    required this.saveLabel,
    this.saveIcon,
    this.onSave,
    this.onClear,
    this.controller,
    this.extraContentBuilder,
    this.topExtraContentBuilder,
    this.bottomExtraContentBuilder,
    this.customField,
    this.autofocus = true,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<NumericEntrySheet> createState() => _NumericEntrySheetState();
}

class _NumericEntrySheetState extends State<NumericEntrySheet> {
  bool _busy = false;
  String? _saveError;

  Future<void> _run(FutureOr<void> Function() action) async {
    if (_busy || !widget.enabled) return;
    setState(() {
      _busy = true;
      _saveError = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted)
        setState(
          () => _saveError = 'Could not save. Your entry is kept. Try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      scrollable: true,
      titleAction: widget.onClear != null
          ? TextButton(
              onPressed: _busy || !widget.enabled
                  ? null
                  : () => _run(widget.onClear!),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.red,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.control),
                ),
              ),
              child: Text(
                'Clear',
                style: context.text.bodyStrong.copyWith(
                  color: context.colors.red,
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.section), // Gap to input

          if (widget.topExtraContentBuilder != null) ...[
            widget.topExtraContentBuilder!(context),
            const SizedBox(height: Spacing.section),
          ],

          if (widget.customField != null)
            widget.customField!
          else if (widget.controller != null)
            TextField(
              controller: widget.controller,
              autofocus: widget.autofocus,
              enabled: widget.enabled && !_busy,
              onChanged: (value) {
                if (_saveError != null) setState(() => _saveError = null);
                widget.onChanged?.call(value);
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: context.text.display.copyWith(
                color: context.colors.textDark,
                fontFamily: 'Cabinet Grotesk',
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.colors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                hintText: widget.hintText,
                hintStyle: context.text.display.copyWith(
                  color: context.colors.textLight,
                  fontFamily: 'Cabinet Grotesk',
                ),
                suffixText: widget.suffixText.isNotEmpty
                    ? widget.suffixText
                    : null,
                suffixStyle: context.text.cardTitle.copyWith(
                  color: context.colors.textMedium,
                  fontFamily: 'General Sans', // explicit fallback for suffix
                ),
                errorText: widget.errorText ?? _saveError,
                errorMaxLines: 3,
                errorStyle: context.text.caption.copyWith(
                  color: context.colors.red,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.control),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.control),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.control),
                  borderSide: BorderSide(
                    color: context.colors.primary,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.control),
                  borderSide: BorderSide(color: context.colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.control),
                  borderSide: BorderSide(color: context.colors.red, width: 1.5),
                ),
              ),
            ),

          if (widget.extraContentBuilder != null) ...[
            // Any custom widgets (like _TimePickerCard, Quick add trio, pre-fill notes)
            const SizedBox(height: Spacing.section),
            widget.extraContentBuilder!(context, widget.controller),
          ],

          const SizedBox(height: Spacing.section), // Gap to CTA
          PrimaryButton(
            label: widget.saveLabel,
            icon: widget.saveIcon,
            isLoading: _busy,
            onPressed: _busy || !widget.enabled || widget.onSave == null
                ? null
                : () => _run(widget.onSave!),
          ),

          if (widget.bottomExtraContentBuilder != null) ...[
            const SizedBox(height: Spacing.stack),
            widget.bottomExtraContentBuilder!(context),
          ],
        ],
      ),
    );
  }
}
