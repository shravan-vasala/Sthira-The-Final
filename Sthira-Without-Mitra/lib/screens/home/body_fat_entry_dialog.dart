import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../widgets/numeric_entry_sheet.dart';

class BodyFatEntryDialog extends ConsumerStatefulWidget {
  const BodyFatEntryDialog({super.key});

  @override
  ConsumerState<BodyFatEntryDialog> createState() => _BodyFatEntryDialogState();
}

class _BodyFatEntryDialogState extends ConsumerState<BodyFatEntryDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  late String _pinnedDateStr;
  late int _accountGeneration;
  bool _isExistingEntry = false;
  bool _isPrefill = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pinnedDateStr = ref.read(dateStringProvider);
    _accountGeneration = ref.read(accountGenerationProvider);
    final log = ref.read(dailyLogProvider);
    if (log.bodyFat != null) {
      _controller.text = log.bodyFat!.toStringAsFixed(1);
      _isExistingEntry = true;
      return;
    }

    final dateStr = ref.read(dateStringProvider);
    final end = DateTime.parse(dateStr).subtract(const Duration(days: 1));
    final start = end.subtract(const Duration(days: 90));
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final logs = ref
        .read(dailyLogRepoProvider)
        .getLogsInRange(fmt(start), fmt(end));
    for (int i = logs.length - 1; i >= 0; i--) {
      final bf = logs[i].bodyFat;
      if (bf != null) {
        _controller.text = bf.toStringAsFixed(1);
        _isPrefill = true;
        break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = _pinnedDateStr;
    final selectedDate = DateTime.parse(selectedDateStr);
    final dateFormatted = DateFormat('EEE, d MMM').format(selectedDate);

    return NumericEntrySheet(
      enabled:
          ref.watch(accountGenerationProvider) == _accountGeneration &&
          !ref.watch(accountTransitionProvider) &&
          !DateTime.parse(
            _pinnedDateStr,
          ).isAfter(DateUtils.dateOnly(ref.watch(clockProvider))),
      title: 'Log Body Fat',
      subtitle: 'Enter your body fat percentage for $dateFormatted',
      controller: _controller,
      autofocus: true,
      suffixText: '%',
      hintText: '0.0',
      errorText: _errorText,
      bottomExtraContentBuilder: _isPrefill
          ? (context) => Center(
              child: Text(
                'Prefilled from a previous measurement',
                style: context.text.caption.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            )
          : null,
      saveLabel: 'Save Body Fat',
      onSave: () async {
        if (_isSaving) return;
        final bf = double.tryParse(_controller.text);
        if (bf != null && bf > 0 && bf <= 100) {
          setState(() => _isSaving = true);
          Haptics.toggle();
          try {
            await ref
                .read(dailyLogProvider.notifier)
                .updateBodyFatForDate(_pinnedDateStr, bf);
            if (mounted) Navigator.of(context).pop();
          } catch (e) {
            setState(() {
              _isSaving = false;
              _errorText = 'Failed to save. Try again.';
            });
          }
        } else {
          Haptics.error();
          setState(
            () => _errorText = 'Please enter a valid percentage (0.1-100)',
          );
        }
      },
      onClear: _isExistingEntry
          ? () async {
              setState(() => _isSaving = true);
              try {
                await ref
                    .read(dailyLogProvider.notifier)
                    .clearBodyFatForDate(_pinnedDateStr);
                if (context.mounted) Navigator.of(context).pop();
              } catch (_) {
                setState(() {
                  _isSaving = false;
                  _errorText = 'Failed to clear. Try again.';
                });
              }
            }
          : null,
    );
  }
}
