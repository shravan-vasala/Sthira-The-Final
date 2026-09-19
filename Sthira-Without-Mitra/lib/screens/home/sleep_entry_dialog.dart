import 'package:flutter/material.dart';
import '../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../providers/app_providers.dart';

import '../../widgets/numeric_entry_sheet.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class SleepEntryDialog extends ConsumerStatefulWidget {
  const SleepEntryDialog({super.key});

  @override
  ConsumerState<SleepEntryDialog> createState() => _SleepEntryDialogState();
}

class _SleepEntryDialogState extends ConsumerState<SleepEntryDialog> {
  final _controller = TextEditingController();
  TimeOfDay? _bedtime;
  TimeOfDay? _waketime;
  bool _hasExistingEntry = false;
  String? _errorText;
  double? _preciseHours;
  bool _isSaving = false;
  late String _pinnedDateStr;
  late int _accountGeneration;

  @override
  void initState() {
    super.initState();
    _pinnedDateStr = ref.read(dateStringProvider);
    _accountGeneration = ref.read(accountGenerationProvider);
    final log = ref.read(dailyLogProvider);
    if (log.sleepHours != null) {
      _preciseHours = log.sleepHours;
      _controller.text = _formatHours(log.sleepHours!);
      _hasExistingEntry = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatHours(double hours) => hours
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0$'), '')
      .replaceFirst(RegExp(r'\.0$'), '');

  String? get _durationLabel {
    final value = _preciseHours ?? double.tryParse(_controller.text);
    if (value == null || !value.isFinite || value < 0 || value > 24) {
      return null;
    }
    final minutes = (value * 60).round();
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  void _updateDurationFromTimes() {
    if (_bedtime == null || _waketime == null) return;
    final bedtime = _bedtime!.hour * 60 + _bedtime!.minute;
    final waketime = _waketime!.hour * 60 + _waketime!.minute;
    final minutes = (waketime - bedtime + 24 * 60) % (24 * 60);
    _preciseHours = minutes / 60;
    _controller.text = _formatHours(_preciseHours!);
    _errorText = null;
  }

  Future<void> _pickTime(bool isBedtime) async {
    final initialTime = isBedtime
        ? (_bedtime ?? const TimeOfDay(hour: 22, minute: 0))
        : (_waketime ?? const TimeOfDay(hour: 6, minute: 0));
    final parentTheme = Theme.of(context);

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(
          data: parentTheme.copyWith(
            colorScheme: parentTheme.colorScheme.copyWith(
              primary: context.colors.primary,
              onPrimary: context.colors.onPrimary,
              onSurface: context.colors.textDark,
            ),
          ),
          child: child,
        );
      },
    );

    if (!mounted ||
        ref.read(accountGenerationProvider) != _accountGeneration ||
        ref.read(accountTransitionProvider)) {
      return;
    }

    if (time != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = time;
        } else {
          _waketime = time;
        }
      });
      _updateDurationFromTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = _pinnedDateStr;
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateUtils.dateOnly(ref.watch(clockProvider));
    final isFuture = selectedDate.isAfter(today);
    final canEdit =
        ref.watch(accountGenerationProvider) == _accountGeneration &&
        !ref.watch(accountTransitionProvider) &&
        !isFuture;
    final dateFormatted = DateFormat('EEE, d MMM').format(selectedDate);
    final nightBeforeFormatted = DateFormat(
      'EEE, d MMM',
    ).format(selectedDate.subtract(const Duration(days: 1)));

    return NumericEntrySheet(
      enabled: canEdit,
      title: 'Log Sleep',
      subtitle:
          'Logging sleep for the night of $nightBeforeFormatted\n(Waking up on $dateFormatted)',
      controller: _controller,
      suffixText: 'hrs',
      hintText: '0.0',
      errorText: _errorText,
      autofocus: true,
      onChanged: (_) {
        setState(() {
          _errorText = null;
          _preciseHours = null;
          _bedtime = null;
          _waketime = null;
        });
      },
      topExtraContentBuilder: _durationLabel == null
          ? null
          : (context) => Center(
              child: Text(
                _durationLabel!,
                key: const ValueKey('sleep-exact-duration'),
                style: context.text.bodyStrong.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),
      saveLabel: isFuture ? 'Cannot log for future date' : 'Save Sleep',
      onSave: isFuture
          ? null
          : () async {
              final sleepHours =
                  _preciseHours ?? double.tryParse(_controller.text);
              if (sleepHours != null && sleepHours >= 0 && sleepHours <= 24) {
                Haptics.toggle();
                setState(() => _isSaving = true);
                try {
                  await ref
                      .read(dailyLogProvider.notifier)
                      .updateSleepForDate(_pinnedDateStr, sleepHours);
                  if (context.mounted) Navigator.of(context).pop();
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              } else {
                Haptics.error();
                setState(() {
                  _errorText = 'Please enter a value between 0 and 24 hours.';
                });
              }
            },
      onClear: _hasExistingEntry
          ? () async {
              setState(() => _isSaving = true);
              try {
                await ref
                    .read(dailyLogProvider.notifier)
                    .clearSleepForDate(_pinnedDateStr);
                if (context.mounted) Navigator.of(context).pop();
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            }
          : null,
      extraContentBuilder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Or calculate automatically from times:',
            style: context.text.body.copyWith(color: context.colors.textMedium),
          ),
          const SizedBox(height: Spacing.stack),
          Row(
            children: [
              Expanded(
                child: _TimePickerCard(
                  key: const ValueKey('sleep-time-bedtime'),
                  title: 'Bedtime',
                  time: _bedtime,
                  onTap: canEdit && !_isSaving ? () => _pickTime(true) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePickerCard(
                  key: const ValueKey('sleep-time-wake'),
                  title: 'Wake up',
                  time: _waketime,
                  onTap: canEdit && !_isSaving ? () => _pickTime(false) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard({
    super.key,
    required this.title,
    required this.time,
    required this.onTap,
  });

  final String title;
  final TimeOfDay? time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label:
          '$title, ${time != null ? time!.format(context) : 'Choose a time'}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time != null ? time!.format(context) : '--:--',
                  style: context.text.cardTitle.copyWith(
                    color: time != null
                        ? context.colors.textDark
                        : context.colors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
