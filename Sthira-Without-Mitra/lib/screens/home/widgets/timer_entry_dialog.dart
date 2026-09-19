import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../models/habit.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/numeric_entry_sheet.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';


class TimerEntryDialog extends ConsumerStatefulWidget {
  final Habit habit;

  const TimerEntryDialog({super.key, required this.habit});

  @override
  ConsumerState<TimerEntryDialog> createState() => _TimerEntryDialogState();
}

class _TimerEntryDialogState extends ConsumerState<TimerEntryDialog>
    with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _lastStartTime;
  int _secondsPassedThisSession = 0;
  late String _initialDateStr;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initialDateStr = ref.read(dateStringProvider);
    // target is in minutes
    _totalSeconds = (widget.habit.target * 60).toInt();
    _remainingSeconds = _totalSeconds;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
    _animationController.value = 1.0;

    Future.microtask(() {
      final prefs = ref.read(sharedPreferencesProvider);
      final savedStartStr = prefs.getString('timer_start_${widget.habit.id}');
      final savedRem = prefs.getInt('timer_rem_${widget.habit.id}');

      if (savedStartStr != null && savedRem != null) {
        final savedStart = DateTime.parse(savedStartStr);
        final elapsed = DateTime.now().difference(savedStart).inSeconds;
        final int restoredRemaining = savedRem - elapsed;

        if (restoredRemaining <= 0) {
          _remainingSeconds = 0;
          _completeTimer();
        } else {
          setState(() {
            _remainingSeconds = restoredRemaining;
            _isRunning = true;
            _lastStartTime = savedStart;
            _secondsPassedThisSession = elapsed;
            _resumeInternalTimer();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final now = DateTime.now();
    setState(() {
      _isRunning = true;
      _lastStartTime = now;
      _secondsPassedThisSession = 0;
    });

    prefs.setString('timer_start_${widget.habit.id}', now.toIso8601String());
    prefs.setInt('timer_rem_${widget.habit.id}', _remainingSeconds);

    _resumeInternalTimer();
  }

  void _resumeInternalTimer() {
    if (_remainingSeconds <= 0) return;
    _animationController.reverse(from: _remainingSeconds / _totalSeconds);

    _timer = Timer.periodic(Motion.instant, (timer) {
      if (!mounted) return;
      if (_lastStartTime == null) return;

      final now = DateTime.now();
      final elapsed = now.difference(_lastStartTime!).inSeconds;

      if (elapsed > _secondsPassedThisSession) {
        setState(() {
          final diff = elapsed - _secondsPassedThisSession;
          _secondsPassedThisSession = elapsed;

          if (_remainingSeconds - diff > 0) {
            _remainingSeconds -= diff;
          } else {
            _completeTimer();
          }
        });
      }
    });
  }

  void _pauseTimer() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove('timer_start_${widget.habit.id}');
    prefs.remove('timer_rem_${widget.habit.id}');

    setState(() {
      _isRunning = false;
      _lastStartTime = null;
      _secondsPassedThisSession = 0;
    });
    _timer?.cancel();
    _animationController.stop();
  }

  void _completeTimer() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove('timer_start_${widget.habit.id}');
    prefs.remove('timer_rem_${widget.habit.id}');

    _timer?.cancel();
    _animationController.stop();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });

    final profile = ref.read(profileProvider);
    if (profile.restTimerVibration) {
      Haptics.success();
    }
    // We're skipping playing a sound here to avoid adding a new audio dependency just for this,
    // but the framework is in place (restTimerSound).

    // Mark habit as completed explicitly rather than toggling, on the exact original date
    ref
        .read(habitCompletionsProvider.notifier)
        .setOverrideForDate(_initialDateStr, widget.habit.id, 'done');

    // Close the dialog automatically after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    return NumericEntrySheet(
      title: widget.habit.name,
      subtitle: 'Closing this sheet will cancel the timer',
      autofocus: false,
      customField: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _animationController.value,
                    strokeWidth: 12,
                    backgroundColor: context.colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colors.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
              Center(
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: context.text.metric.copyWith(
                    color: context.colors.textDark,
                    fontFamily: 'Cabinet Grotesk',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      onClear: (_remainingSeconds < _totalSeconds && !_isRunning && _remainingSeconds > 0) ? () {
        setState(() {
          _remainingSeconds = _totalSeconds;
          _animationController.value = 1.0;
        });
        final prefs = ref.read(sharedPreferencesProvider);
        prefs.remove('timer_start_${widget.habit.id}');
        prefs.remove('timer_rem_${widget.habit.id}');
      } : null,
      saveLabel: _remainingSeconds == 0
          ? 'Done'
          : (_isRunning
                ? 'Pause'
                : (_remainingSeconds == _totalSeconds
                      ? 'Start'
                      : 'Resume')),
      saveIcon: _remainingSeconds == 0
          ? Icons.check_circle_rounded
          : (_isRunning
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded),
      onSave: _remainingSeconds == 0
          ? () => Navigator.of(context).pop()
          : (_isRunning ? _pauseTimer : _startTimer),
    );
  }
}
