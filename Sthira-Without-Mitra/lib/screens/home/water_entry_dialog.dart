import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../models/habit.dart';

import '../../widgets/numeric_entry_sheet.dart';
import '../../theme/app_motion.dart';

class WaterEntryDialog extends ConsumerStatefulWidget {
  const WaterEntryDialog({super.key});

  @override
  ConsumerState<WaterEntryDialog> createState() => _WaterEntryDialogState();
}

class _WaterEntryDialogState extends ConsumerState<WaterEntryDialog> {
  final _controller = TextEditingController();
  bool _hasExistingEntry = false;
  int _currentAmount = 0;
  bool _isSaving = false;
  String? _errorText;
  late String _pinnedDateStr;
  late int _accountGeneration;

  @override
  void initState() {
    super.initState();
    _pinnedDateStr = ref.read(dateStringProvider);
    _accountGeneration = ref.read(accountGenerationProvider);
    final log = ref.read(dailyLogProvider);
    if (log.waterMl != null && log.waterMl! >= 0) {
      _currentAmount = log.waterMl!;
      _controller.text = _currentAmount.toString();
      _hasExistingEntry = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addAmount(int amount) {
    if (_isSaving) return;
    setState(() {
      int currentTextAmount = int.tryParse(_controller.text) ?? 0;
      if (currentTextAmount < 0) currentTextAmount = 0;
      _errorText = null;
      _currentAmount = currentTextAmount + amount;
      _controller.text = _currentAmount.toString();
    });
  }

  void _onTextChanged(String val) {
    if (_isSaving) return;
    setState(() {
      _errorText = null;
      int parsed = int.tryParse(val) ?? 0;
      if (parsed < 0) parsed = 0;
      _currentAmount = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = _pinnedDateStr;
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateUtils.dateOnly(ref.watch(clockProvider));
    final isFuture = selectedDate.isAfter(today);
    final dateFormatted = DateFormat('EEE, d MMM').format(selectedDate);

    // Fetch Target
    final habits = ref.watch(habitsProvider);
    final waterHabit = habits.where((h) => h.id == 'water').firstOrNull;

    double? targetInMl;
    if (waterHabit != null && waterHabit.target > 0) {
      targetInMl = waterHabit.target.toDouble();
      if (waterHabit.unit.toLowerCase() == 'l' ||
          waterHabit.unit.toLowerCase() == 'liters') {
        targetInMl *= 1000;
      }
    }

    final hasTarget =
        targetInMl != null && targetInMl.isFinite && targetInMl > 0;
    final progressFraction = hasTarget
        ? (_currentAmount / targetInMl).clamp(0.0, 1.0)
        : 0.0;
    final enteredAmount = int.tryParse(_controller.text.trim());
    final isGoalReached =
        hasTarget &&
        enteredAmount != null &&
        enteredAmount >= 0 &&
        (waterHabit!.goalDirection == GoalDirection.atMost
            ? _currentAmount <= targetInMl
            : _currentAmount >= targetInMl);

    return NumericEntrySheet(
      enabled:
          ref.watch(accountGenerationProvider) == _accountGeneration &&
          !ref.watch(accountTransitionProvider) &&
          !DateTime.parse(
            _pinnedDateStr,
          ).isAfter(DateUtils.dateOnly(ref.watch(clockProvider))),
      title: 'Water Intake',
      subtitle: dateFormatted,
      controller: _controller,
      autofocus: true,
      suffixText: 'ml',
      hintText: '0',
      errorText: _errorText,
      onChanged: _onTextChanged,
      topExtraContentBuilder: isFuture
          ? null
          : (context) => Column(
              children: [
                Wrap(
                  spacing: Spacing.stack,
                  runSpacing: Spacing.inline,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_currentAmount ml',
                          style: context.text.display.copyWith(
                            color: isGoalReached
                                ? context.colors.green
                                : context.colors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasTarget)
                          Text(
                            'Goal: ${targetInMl?.toInt()} ml',
                            style: context.text.body.copyWith(
                              color: context.colors.textMedium,
                            ),
                          )
                        else
                          Text(
                            'No goal set',
                            style: context.text.body.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                      ],
                    ),
                    if (isGoalReached)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Goal reached',
                              style: context.text.caption.copyWith(
                                color: context.colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasTarget)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progressFraction),
                    duration: Motion.standard,
                    curve: Motion.enter,
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: context.colors.primary.withValues(
                            alpha: 0.1,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isGoalReached
                                ? context.colors.green
                                : context.colors.primary,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
      customField: isFuture
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: context.colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You cannot log water for future dates.',
                      style: context.text.caption.copyWith(
                        color: context.colors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      extraContentBuilder: isFuture
          ? null
          : (context, _) => Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _addAmount(250),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      side: BorderSide(
                        color: context.colors.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.control),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('+ 250ml', style: context.text.bodyStrong),
                  ),
                ),
                const SizedBox(width: Spacing.inline),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _addAmount(500),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      side: BorderSide(
                        color: context.colors.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.control),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('+ 500ml', style: context.text.bodyStrong),
                  ),
                ),
                const SizedBox(width: Spacing.inline),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _addAmount(1000),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      side: BorderSide(
                        color: context.colors.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.control),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('+ 1L', style: context.text.bodyStrong),
                  ),
                ),
              ],
            ),
      onClear: _hasExistingEntry && !_isSaving
          ? () async {
              setState(() {
                _isSaving = true;
                _errorText = null;
              });
              try {
                await ref
                    .read(dailyLogProvider.notifier)
                    .clearWaterForDate(_pinnedDateStr);
                if (context.mounted) Navigator.of(context).pop();
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            }
          : null,
      saveLabel: 'Save Intake',
      onSave: isFuture
          ? null
          : () async {
              if (_isSaving) return;
              final amount = int.tryParse(_controller.text.trim());
              if (amount == null || amount < 0) {
                setState(
                  () => _errorText =
                      'Enter a whole number of ml (0 or more). Use Clear to remove an entry.',
                );
                return;
              }
              setState(() {
                _isSaving = true;
                _errorText = null;
              });
              try {
                await ref
                    .read(dailyLogProvider.notifier)
                    .updateWaterForDate(_pinnedDateStr, amount);
                if (context.mounted) Navigator.of(context).pop();
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
    );
  }
}
