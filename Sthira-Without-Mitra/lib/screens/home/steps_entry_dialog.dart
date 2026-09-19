import 'package:flutter/material.dart';
import '../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../widgets/numeric_entry_sheet.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class StepsEntryDialog extends ConsumerStatefulWidget {
  const StepsEntryDialog({super.key});

  @override
  ConsumerState<StepsEntryDialog> createState() => _StepsEntryDialogState();
}

class _StepsEntryDialogState extends ConsumerState<StepsEntryDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  late String _pinnedDateStr;
  late int _accountGeneration;
  bool _hasExistingEntry = false;
  bool _isHealthConnect = false;

  @override
  void initState() {
    super.initState();
    _pinnedDateStr = ref.read(dateStringProvider);
    _accountGeneration = ref.read(accountGenerationProvider);
    final log = ref.read(dailyLogProvider);
    if (log.steps != null && log.steps! >= 0) {
      _controller.text = log.steps.toString();
      _hasExistingEntry = true;
    }
    if (log.stepsSource == 'healthConnect') {
      _isHealthConnect = true;
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
    final isToday =
        DateTime.now().year == selectedDate.year &&
        DateTime.now().month == selectedDate.month &&
        DateTime.now().day == selectedDate.day;

    final monthStr = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][selectedDate.month - 1];
    final dateFormatted = '${selectedDate.day} $monthStr';

    return NumericEntrySheet(
      enabled:
          ref.watch(accountGenerationProvider) == _accountGeneration &&
          !ref.watch(accountTransitionProvider) &&
          !DateTime.parse(
            _pinnedDateStr,
          ).isAfter(DateUtils.dateOnly(ref.watch(clockProvider))),
      title: 'Log Steps',
      subtitle: isToday
          ? 'Enter your step count for today'
          : 'Enter your step count for $dateFormatted',
      controller: _controller,
      suffixText: 'steps',
      hintText: '0',
      errorText: _errorText,
      autofocus: true,
      onChanged: (_) {
        if (_errorText != null) {
          setState(() => _errorText = null);
        }
      },
      extraContentBuilder: _isHealthConnect
          ? (context, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  size: 16,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Synced from Health Connect. Manual saves will override sync for this day.',
                    style: context.text.micro.copyWith(
                      color: context.colors.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : null,
      saveLabel: 'Save Steps',
      onSave: () async {
        if (_controller.text.trim().isEmpty) {
          Haptics.toggle();
          await ref
              .read(dailyLogProvider.notifier)
              .clearStepsForDate(_pinnedDateStr);
          if (mounted) Navigator.of(context).pop();
          return;
        }

        final steps = int.tryParse(_controller.text);
        if (steps != null && steps >= 0) {
          Haptics.toggle();
          await ref
              .read(dailyLogProvider.notifier)
              .updateStepsForDate(_pinnedDateStr, steps);
          if (mounted) Navigator.of(context).pop();
        } else {
          Haptics.error();
          setState(() => _errorText = 'Please enter a valid number (≥ 0)');
        }
      },
      onClear: _hasExistingEntry
          ? () async {
              await ref
                  .read(dailyLogProvider.notifier)
                  .clearStepsForDate(_pinnedDateStr);
              if (mounted) Navigator.of(context).pop();
            }
          : null,
    );
  }
}
