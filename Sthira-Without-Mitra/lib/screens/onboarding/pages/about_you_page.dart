import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_text_field.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class AboutYouPage extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController coachController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final FocusNode? nameFocus;
  final FocusNode? heightFocus;
  final FocusNode? weightFocus;
  final bool useKg;
  final bool showErrors;
  final VoidCallback onToggleUnit;

  const AboutYouPage({
    super.key,
    required this.nameController,
    required this.coachController,
    required this.heightController,
    required this.weightController,
    this.nameFocus,
    this.heightFocus,
    this.weightFocus,
    required this.useKg,
    this.showErrors = false,
    required this.onToggleUnit,
  });

  @override
  State<AboutYouPage> createState() => _AboutYouPageState();
}

class _AboutYouPageState extends State<AboutYouPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  String _nameError = '';
  String _heightError = '';
  String _weightError = '';

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: Motion.deliberate,
    );
    _staggerController.forward();

    widget.nameController.addListener(_validateInputs);
    widget.heightController.addListener(_validateInputs);
    widget.weightController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _staggerController.dispose();
    widget.nameController.removeListener(_validateInputs);
    widget.heightController.removeListener(_validateInputs);
    widget.weightController.removeListener(_validateInputs);
    super.dispose();
  }

  @override
  void didUpdateWidget(AboutYouPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useKg != widget.useKg ||
        oldWidget.showErrors != widget.showErrors) {
      _validateInputs();
    }
  }

  void _validateInputs() {
    String nError = '';
    String hError = '';
    String wError = '';

    if (widget.showErrors && widget.nameController.text.trim().isEmpty) {
      nError = 'Required';
    }

    final hText = widget.heightController.text;
    if (hText.isNotEmpty) {
      final h = double.tryParse(hText);
      if (h == null) {
        hError = 'Invalid number';
      } else if (h < 100 || h > 230) {
        hError = 'Must be 100-230 cm';
      }
    }

    final wText = widget.weightController.text;
    if (wText.isNotEmpty) {
      final w = double.tryParse(wText);
      if (w == null) {
        wError = 'Invalid number';
      } else {
        final double wKg = widget.useKg ? w : w / 2.20462;
        if (wKg < 30 || wKg > 200) {
          wError = widget.useKg ? 'Must be 30-200 kg' : 'Must be 66-440 lb';
        }
      }
    }

    if (nError != _nameError ||
        hError != _heightError ||
        wError != _weightError) {
      setState(() {
        _nameError = nError;
        _heightError = hError;
        _weightError = wError;
      });
    }
  }

  Widget _buildAnimEntrance(int index, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final start = index * 0.1;
    final end = (start + 0.5).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, animChild) {
        final slide = CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Motion.enter),
        ).value;
        final fade = CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end - 0.2, curve: Motion.exit),
        ).value;
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - slide)),
            child: animChild,
          ),
        );
      },
      child: child,
    );
  }

  Widget _measurementFields(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 48;
    {
      final stacked =
          availableWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      final width = stacked ? availableWidth : (availableWidth - 16) / 2;
      Widget field({
        required TextEditingController controller,
        required FocusNode? focus,
        required String label,
        required String hint,
        required String error,
      }) => SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: controller,
              focusNode: focus,
              labelText: label,
              hintText: hint,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  error,
                  style: context.text.caption.copyWith(
                    color: context.colors.red,
                  ),
                ),
              ),
          ],
        ),
      );
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          field(
            controller: widget.heightController,
            focus: widget.heightFocus,
            label: 'Height (Optional)',
            hint: '153 cm',
            error: _heightError,
          ),
          field(
            controller: widget.weightController,
            focus: widget.weightFocus,
            label: 'Weight (Optional)',
            hint: widget.useKg ? '66 kg' : '145 lb',
            error: _weightError,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                _buildAnimEntrance(
                  0,
                  Column(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 48,
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'About You',
                        textAlign: TextAlign.center,
                        style: context.text.display.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                _buildAnimEntrance(
                  1,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: widget.nameController,
                        focusNode: widget.nameFocus,
                        labelText: 'Your Name',
                        hintText: 'Eg. Bodamma',
                        capitalization: TextCapitalization.words,
                        prefixIcon: Icons.badge_rounded,
                      ),
                      if (_nameError.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 4),
                          child: Text(
                            _nameError,
                            style: context.text.caption.copyWith(
                              color: context.colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                _buildAnimEntrance(
                  2,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: widget.coachController,
                        labelText: 'Coach Name (Optional)',
                        hintText: 'Eg. Shravan',
                        capitalization: TextCapitalization.words,
                        prefixIcon: Icons.sports_rounded,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4),
                        child: Text(
                          'What should your AI coach call itself?',
                          style: context.text.caption.copyWith(
                            color: context.colors.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                _buildAnimEntrance(3, _measurementFields(context)),
                const Spacer(flex: 3),
                _buildAnimEntrance(
                  4,
                  Center(
                    child: GestureDetector(
                      onTap: widget.onToggleUnit,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              color: context.colors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Switch to ${widget.useKg ? 'Pounds' : 'Kilograms'}',
                              style: context.text.caption.copyWith(
                                color: context.colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
