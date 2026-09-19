import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format_units.dart';
import '../../providers/app_providers.dart';
import '../../models/workout_plan.dart';
import '../../models/exercise_log.dart';
import '../../models/user_profile.dart';
import '../../utils/exercise_log_save.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/primary_button.dart';

class LogDataDialog extends ConsumerStatefulWidget {
  const LogDataDialog({super.key, required this.exercise});
  final Exercise exercise;
  @override
  ConsumerState<LogDataDialog> createState() => _LogDataDialogState();
}

class _LogDataDialogState extends ConsumerState<LogDataDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _repsControllers;
  late final List<TextEditingController> _weightControllers;
  late final List<double> _weightKgSources;
  late final String _date;
  late final int _generation;
  late final UserProfile _profile;
  ExerciseLog? _existing;
  ExerciseLog? _lastLog;
  bool _saving = false;
  String? _error;
  bool get _isTimed => plannedDurationTargets(widget.exercise).isNotEmpty;
  List<int> get _targets => _isTimed
      ? plannedDurationTargets(widget.exercise)
      : plannedRepTargets(widget.exercise);

  String _weightText(double kg) => convertFromKg(_profile, kg)
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');

  @override
  void initState() {
    super.initState();
    _date = ref.read(dateStringProvider);
    _generation = ref.read(accountGenerationProvider);
    _profile = ref.read(profileProvider);
    final repo = ref.read(exerciseLogRepoProvider);
    _existing = repo.getLog(
      _date,
      widget.exercise.instanceId ?? widget.exercise.name ?? '',
    );
    _lastLog = repo.getLastLog(widget.exercise.name ?? '', beforeDate: _date);
    final targets = _targets;
    final count = [
      widget.exercise.setCount,
      _existing?.sets.length ?? 0,
      _existing?.sets.fold<int>(
            0,
            (count, set) =>
                (set.setNumber ?? 0) > count ? set.setNumber! : count,
          ) ??
          0,
      1,
    ].reduce((a, b) => a > b ? a : b);
    _repsControllers = List.generate(count, (i) {
      final existing = loggedSetNumber(_existing, i + 1);
      final target = _existing != null
          ? (_isTimed ? existing?.durationSeconds : existing?.reps)
          : (i < targets.length ? targets[i] : null);
      return TextEditingController(text: target?.toString() ?? '');
    });
    _weightKgSources = List.generate(
      count,
      (i) =>
          loggedSetNumber(_existing, i + 1)?.weight ??
          widget.exercise.weightKg ??
          loggedSetNumber(_lastLog, i + 1)?.weight ??
          0,
    );
    _weightControllers = List.generate(
      count,
      (i) => TextEditingController(text: _weightText(_weightKgSources[i])),
    );
  }

  @override
  void dispose() {
    for (final c in [..._repsControllers, ..._weightControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillFromPlan() {
    final targets = _targets;
    for (var i = 0; i < _repsControllers.length; i++) {
      _repsControllers[i].text = i < targets.length
          ? targets[i].toString()
          : '';
      _weightKgSources[i] =
          widget.exercise.weightKg ??
          loggedSetNumber(_lastLog, i + 1)?.weight ??
          0;
      _weightControllers[i].text = _weightText(_weightKgSources[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = _profile.useKg ? 'kg' : 'lb';
    final canLog = supportsExerciseLogging(widget.exercise);
    return PopScope(
      canPop: !_saving,
      child: AppSheet(
        title:
            'Log: ${widget.exercise.displayName ?? widget.exercise.name ?? ''}',
        subtitle: DateFormat('EEE, d MMM').format(DateTime.parse(_date)),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!canLog)
                const Text(
                  'This target uses distance or an unclear unit. Confirm the expert guidance; do not record it as repetitions.',
                )
              else ...[
                Text(
                  _isTimed
                      ? 'Enter the seconds you completed. Leave a set blank if you did not do it.'
                      : 'Use 0 $unit for bodyweight. Leave reps blank for sets you did not do.',
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
                const SizedBox(height: Spacing.stack),
                ...List.generate(
                  _repsControllers.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.block),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set ${i + 1}', style: context.text.bodyStrong),
                        const SizedBox(height: Spacing.inline),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fields = [
                              TextFormField(
                                key: ValueKey(
                                  '${_isTimed ? 'duration' : 'reps'}-$i',
                                ),
                                controller: _repsControllers[i],
                                enabled: !_saving,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                style: AppTheme.numeric(context.text.body),
                                decoration: InputDecoration(
                                  labelText: _isTimed ? 'Seconds' : 'Reps',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (raw) {
                                  if (raw == null || raw.trim().isEmpty)
                                    return null;
                                  final reps = int.tryParse(raw.trim());
                                  return reps == null || reps <= 0
                                      ? (_isTimed
                                            ? 'Enter positive whole seconds'
                                            : 'Enter positive whole reps')
                                      : null;
                                },
                              ),
                              if (!_isTimed)
                                TextFormField(
                                  key: ValueKey('weight-$i'),
                                  controller: _weightControllers[i],
                                  enabled: !_saving,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textInputAction:
                                      i == _repsControllers.length - 1
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  style: AppTheme.numeric(context.text.body),
                                  decoration: InputDecoration(
                                    labelText: 'Weight ($unit)',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (raw) {
                                    if (_repsControllers[i].text.trim().isEmpty)
                                      return null;
                                    final weight = double.tryParse(
                                      raw?.trim().isEmpty ?? true
                                          ? '0'
                                          : raw!.trim(),
                                    );
                                    return weight == null ||
                                            !weight.isFinite ||
                                            weight < 0
                                        ? 'Enter 0 or a positive weight'
                                        : null;
                                  },
                                ),
                            ];
                            if (_isTimed) return fields.first;
                            if (constraints.maxWidth < 300 ||
                                MediaQuery.textScalerOf(context).scale(1) >
                                    1.3) {
                              return Column(
                                children: [
                                  fields[0],
                                  const SizedBox(height: Spacing.stack),
                                  fields[1],
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: fields[0]),
                                const SizedBox(width: Spacing.stack),
                                Expanded(child: fields[1]),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_targets.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              _fillFromPlan();
                              _save();
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Log as planned',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.stack),
                ],
                PrimaryButton(
                  label: _saving ? 'Saving…' : 'Save Log',
                  onPressed: _saving ? null : _save,
                ),
              ],
              if (_existing != null)
                Center(
                  child: TextButton(
                    onPressed: _saving ? null : _remove,
                    child: const Text('Remove log'),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: Spacing.stack),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: context.text.caption.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final sets = <SetLog>[];
    for (var i = 0; i < _repsControllers.length; i++) {
      final raw = _repsControllers[i].text.trim();
      if (raw.isEmpty) continue;
      final weight = double.parse(
        _weightControllers[i].text.trim().isEmpty
            ? '0'
            : _weightControllers[i].text.trim(),
      );
      sets.add(
        SetLog(
          setNumber: i + 1,
          reps: _isTimed ? null : int.parse(raw),
          durationSeconds: _isTimed ? int.parse(raw) : null,
          weight: _isTimed
              ? 0
              : _weightControllers[i].text.trim() ==
                    _weightText(_weightKgSources[i])
              ? _weightKgSources[i]
              : convertToKg(_profile, weight),
        ),
      );
    }
    if (sets.isEmpty) {
      setState(
        () => _error =
            'Enter ${_isTimed ? 'seconds' : 'reps'} for at least one set. Use Remove log to clear an existing log.',
      );
      return;
    }
    await _persist(sets);
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this log?'),
        content: const Text(
          'This removes the sets saved for this exercise on this date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep log'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _persist(const [], remove: true);
  }

  Future<void> _persist(List<SetLog> sets, {bool remove = false}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      ensureExerciseSaveScope(ref, _generation, _date);
      final repo = ref.read(exerciseLogRepoProvider);
      if (remove) {
        await repo.deleteLog(
          _date,
          widget.exercise.instanceId ?? widget.exercise.name ?? '',
        );
      } else {
        await repo.saveLog(
          ExerciseLog(
            date: _date,
            instanceId:
                widget.exercise.instanceId ?? widget.exercise.name ?? '',
            exerciseName: widget.exercise.name ?? '',
            sets: sets,
          ),
        );
      }
      ensureExerciseSaveScope(ref, _generation, _date);
      ref.read(exerciseLogsUpdateProvider.notifier).state++;
      final result = await checkAndSavePr(
        ref: ref,
        exerciseName: widget.exercise.name ?? '',
        sets: sets,
        expectedGeneration: _generation,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = remove
          ? 'Log removed'
          : result.hasAnyNewPr
          ? 'Logged ${widget.exercise.name ?? ''} · New personal record!'
          : 'Logged ${widget.exercise.name ?? ''}';
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Could not finish saving. Your entries are still here; try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
