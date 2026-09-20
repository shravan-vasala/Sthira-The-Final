import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../../models/daily_log.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_motion.dart';
import '../../../providers/app_providers.dart';
import '../../../repositories/daily_log_repository.dart';
import '../../../services/haptics.dart';
import '../../../widgets/app_text_field.dart';

class DayFeelingCard extends ConsumerStatefulWidget {
  final String dateStr;
  final String? initialFeeling;
  final String? initialNote;
  final bool alwaysShowNote;

  const DayFeelingCard({
    super.key,
    required this.dateStr,
    this.initialFeeling,
    this.initialNote,
    this.alwaysShowNote = false,
  });

  @override
  ConsumerState<DayFeelingCard> createState() => _DayFeelingCardState();
}

final _checkInLogProvider = StreamProvider.autoDispose
    .family<DailyLog?, String>((ref, date) {
      ref.watch(accountGenerationProvider);
      return ref.watch(dailyLogRepoProvider).watchLog(date);
    });

const _feelingLabels = {
  'veryLow': 'Struggled',
  'low': 'Tired',
  'okay': 'Okay',
  'good': 'Steady',
  'great': 'Thriving',
};

/// A private summary on Home; the editor keeps the existing save lifecycle.
class DayCheckInTile extends ConsumerWidget {
  const DayCheckInTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(dailyLogProvider);
    final generation = ref.watch(accountGenerationProvider);
    final transitioning = ref.watch(accountTransitionProvider);
    final hydrating = ref.watch(accountHydratingProvider);
    final recovery = ref.watch(_reflectionRecoveryProvider)[log.date];
    final draft = recovery != null && recovery.draft.isCurrentAccount()
        ? recovery
        : null;
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime.tryParse(log.date);
    final future = date == null || date.isAfter(today);
    final enabled = !future && !transitioning && !hydrating;
    final feeling = _feelingLabels[log.dayFeeling];
    final hasNote = log.dayNote?.trim().isNotEmpty ?? false;
    final summary = [?feeling, if (hasNote) 'Note added'].join(' \u00b7 ');
    final subtitle = transitioning || hydrating
        ? 'Loading check-in\u2026'
        : future
        ? 'Check in when this day arrives.'
        : draft != null
        ? draft.failed
              ? 'Not saved. Tap to retry.'
              : 'Saving\u2026'
        : summary.isNotEmpty
        ? summary
        : date == today
        ? 'How did today feel?'
        : 'How did this day feel?';

    return SurfaceCard(
      onTap: !enabled
          ? null
          : () {
              if (ref.read(accountTransitionProvider) ||
                  ref.read(accountHydratingProvider) ||
                  generation != ref.read(accountGenerationProvider)) {
                return;
              }
              showAppBottomSheet<void>(
                context: context,
                builder: (_) => _DailyCheckInSheet(
                  date: log.date,
                  accountGeneration: generation,
                ),
              );
            },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.stack),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Icon(
              Icons.self_improvement_rounded,
              color: context.colors.primary,
              size: IconSize.nav,
            ),
          ),
          const SizedBox(width: Spacing.block),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily check-in', style: context.text.cardTitle),
                const SizedBox(height: Spacing.textPair),
                Semantics(
                  liveRegion: draft?.failed ?? false,
                  child: Text(subtitle, style: context.text.caption),
                ),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: Spacing.inline),
            Icon(
              Icons.chevron_right_rounded,
              size: IconSize.row,
              color: context.colors.textMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyCheckInSheet extends ConsumerWidget {
  const _DailyCheckInSheet({
    required this.date,
    required this.accountGeneration,
  });

  final String date;
  final int accountGeneration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void closeForAccountChange() {
      if (!context.mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isActive) return;
      final navigator = Navigator.of(context);
      // Any confirmation above this editor belongs to the departing account.
      navigator.popUntil((candidate) => candidate == route);
      if (route.isCurrent) navigator.pop();
    }

    ref.listen(accountGenerationProvider, (_, next) {
      if (next != accountGeneration) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => closeForAccountChange(),
        );
      }
    });
    ref.listen(accountTransitionProvider, (_, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => closeForAccountChange(),
        );
      }
    });
    if (ref.watch(accountGenerationProvider) != accountGeneration ||
        ref.watch(accountTransitionProvider)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => closeForAccountChange(),
      );
      return const SizedBox.shrink();
    }

    // The calendar can move while this route is open; edits keep their date.
    final log =
        ref.watch(_checkInLogProvider(date)).valueOrNull ??
        ref.read(dailyLogRepoProvider).getOrCreate(date);
    return AppSheet(
      title: 'Daily check-in',
      subtitle: DateFormat('EEE, d MMM yyyy').format(DateTime.parse(date)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DayFeelingCard(
            key: ValueKey((accountGeneration, date)),
            dateStr: date,
            initialFeeling: log.dayFeeling,
            initialNote: log.dayNote,
            alwaysShowNote: true,
          ),
          const SizedBox(height: Spacing.block),
          PrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

typedef _ReflectionDraft = ({
  String date,
  String? feeling,
  String? note,
  int revision,
  Object token,
  bool Function() isCurrentAccount,
  DailyLogRepository repository,
  void Function(bool failed) settled,
});

// Unsaved reflections survive page changes within the current account session.
final _reflectionRecoveryProvider =
    StateProvider<Map<String, ({_ReflectionDraft draft, bool failed})>>((ref) {
      ref.watch(accountGenerationProvider);
      return {};
    });

// One writer per account also orders saves across Home and history editors.
final _reflectionWriterProvider = Provider((ref) {
  ref.watch(accountGenerationProvider);
  return _ReflectionWriter();
});

class _ReflectionWriter {
  final _queue = <_ReflectionDraft>[];
  bool _writing = false;

  void enqueue(_ReflectionDraft draft) {
    _queue.add(draft);
    if (!_writing) unawaited(_drain());
  }

  Future<void> _drain() async {
    _writing = true;
    try {
      while (_queue.isNotEmpty) {
        final draft = _queue.removeAt(0);
        if (!draft.isCurrentAccount()) continue;
        try {
          await draft.repository.updateCheckIn(
            draft.date,
            draft.feeling,
            draft.note,
          );
          draft.settled(false);
        } catch (_) {
          draft.settled(true);
        }
      }
    } finally {
      _writing = false;
    }
  }
}

enum _SaveStatus { idle, waiting, saving, saved, failed }

class _DayFeelingCardState extends ConsumerState<DayFeelingCard> {
  static const _storedValues = ['veryLow', 'low', 'okay', 'good', 'great'];
  static const _labels = ['Struggled', 'Tired', 'Okay', 'Steady', 'Thriving'];

  late final TextEditingController _noteCtrl;
  final _noteFocus = FocusNode();
  Timer? _debounce;
  _ReflectionDraft? _pendingDraft;
  _ReflectionDraft? _failedDraft;
  _ReflectionDraft? _activeDraft;
  bool _leaving = false;
  int _revision = 0;
  String? _feeling;
  _SaveStatus _status = _SaveStatus.idle;
  bool _showNote = false;
  bool _resetOnNextUpdate = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.initialNote);
    _feeling = widget.initialFeeling;
    _restoreDraft();
  }

  @override
  void didUpdateWidget(covariant DayFeelingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_resetOnNextUpdate || widget.dateStr != oldWidget.dateStr) {
      _resetOnNextUpdate = false;
      _flushPendingNote();
      _revision++;
      _noteFocus.unfocus();
      _noteCtrl.text = widget.initialNote ?? '';
      _feeling = widget.initialFeeling;
      _showNote = false;
      _status = _SaveStatus.idle;
      _failedDraft = null;
      _activeDraft = null;
      _restoreDraft();
    } else if (_status == _SaveStatus.idle || _status == _SaveStatus.saved) {
      if (widget.initialNote != oldWidget.initialNote) {
        _noteCtrl.text = widget.initialNote ?? '';
      }
      if (widget.initialFeeling != oldWidget.initialFeeling) {
        _feeling = widget.initialFeeling;
      }
    }
  }

  @override
  void deactivate() {
    _leaving = true;
    _flushPendingNote();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _leaving = false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _noteFocus.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _restoreDraft() {
    final entry = ref.read(_reflectionRecoveryProvider)[widget.dateStr];
    if (entry == null || !entry.draft.isCurrentAccount()) return;
    _activeDraft = entry.draft;
    _feeling = entry.draft.feeling;
    _noteCtrl.text = entry.draft.note ?? '';
    _status = entry.failed ? _SaveStatus.failed : _SaveStatus.saving;
    _failedDraft = entry.failed ? entry.draft : null;
  }

  _ReflectionDraft _draft(String? feeling, String? note) {
    // Capture the account guard before navigation disposes this editor.
    final generation = ref.read(accountGenerationProvider.notifier);
    final transition = ref.read(accountTransitionProvider.notifier);
    final recovery = ref.read(_reflectionRecoveryProvider.notifier);
    final account = generation.state;
    final date = widget.dateStr;
    bool isCurrentAccount() =>
        generation.mounted &&
        transition.mounted &&
        generation.state == account &&
        !transition.state;
    late final _ReflectionDraft draft;
    draft = (
      date: date,
      feeling: feeling,
      note: note,
      revision: ++_revision,
      token: Object(),
      isCurrentAccount: isCurrentAccount,
      repository: ref.read(dailyLogRepoProvider),
      settled: (failed) {
        if (!recovery.mounted ||
            !isCurrentAccount() ||
            !identical(recovery.state[date]?.draft.token, draft.token)) {
          return;
        }
        final entries = {...recovery.state};
        if (failed) {
          entries[date] = (draft: draft, failed: true);
        } else {
          entries.remove(date);
        }
        recovery.state = entries;
      },
    );
    _activeDraft = draft;
    recovery.state = {...recovery.state, date: (draft: draft, failed: false)};
    return draft;
  }

  bool _isCurrent(_ReflectionDraft draft) =>
      mounted &&
      !_leaving &&
      draft.isCurrentAccount() &&
      draft.date == widget.dateStr &&
      identical(_activeDraft?.token, draft.token);

  void _cancelPendingNote() {
    _debounce?.cancel();
    _debounce = null;
    _pendingDraft = null;
  }

  void _flushPendingNote() {
    final draft = _pendingDraft;
    _cancelPendingNote();
    if (draft != null) _enqueue(draft);
  }

  void _enqueue(_ReflectionDraft draft) {
    if (_isCurrent(draft)) setState(() => _status = _SaveStatus.saving);
    if (draft.isCurrentAccount()) {
      final recovery = ref.read(_reflectionRecoveryProvider.notifier);
      final entry = recovery.state[draft.date];
      if (entry != null &&
          entry.failed &&
          identical(entry.draft.token, draft.token)) {
        recovery.state = {
          ...recovery.state,
          draft.date: (draft: draft, failed: false),
        };
      }
    }
    ref.read(_reflectionWriterProvider).enqueue(draft);
  }

  void _onNoteChanged(String text) {
    _cancelPendingNote();
    _pendingDraft = _draft(_feeling, text);
    _failedDraft = null;
    _status = _SaveStatus.waiting;
    _debounce = Timer(const Duration(milliseconds: 800), _flushPendingNote);
    setState(() {});
  }

  void _selectFeeling(int index) {
    if (_feeling == _storedValues[index]) return;
    Haptics.tap();
    _cancelPendingNote();
    setState(() {
      _feeling = _storedValues[index];
      _status = _SaveStatus.waiting;
      _failedDraft = null;
    });
    _enqueue(_draft(_feeling, _noteCtrl.text));
  }

  Future<void> _clearCheckIn() async {
    final revision = _revision;
    final date = widget.dateStr;
    final generation = ref.read(accountGenerationProvider);
    if (_noteCtrl.text.trim().isNotEmpty) {
      final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear this check-in?'),
          content: const Text(
            'This removes the feeling and note for this day.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        ),
      );
      if (clear != true) return;
    }
    if (!mounted ||
        revision != _revision ||
        date != widget.dateStr ||
        generation != ref.read(accountGenerationProvider) ||
        ref.read(accountTransitionProvider)) {
      return;
    }
    _cancelPendingNote();
    _noteFocus.unfocus();
    setState(() {
      _feeling = null;
      _noteCtrl.clear();
      _showNote = false;
      _status = _SaveStatus.waiting;
      _failedDraft = null;
    });
    _enqueue(_draft(null, null));
  }

  void _toggleNote() {
    Haptics.tap();
    if (_showNote) {
      _flushPendingNote();
      _noteFocus.unfocus();
    }
    setState(() => _showNote = !_showNote);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountGenerationProvider, (previous, next) {
      _cancelPendingNote();
      _revision++;
      _activeDraft = null;
      _resetOnNextUpdate = true;
      _noteFocus.unfocus();
      _noteCtrl.clear();
      setState(() {
        _feeling = null;
        _showNote = false;
        _failedDraft = null;
        _status = _SaveStatus.idle;
      });
    });
    ref.listen(_reflectionRecoveryProvider, (previous, next) {
      final prior = previous?[widget.dateStr];
      final entry = next[widget.dateStr];
      if (prior == null ||
          !identical(prior.draft.token, _activeDraft?.token) ||
          !prior.draft.isCurrentAccount()) {
        return;
      }
      if (entry == null) {
        setState(() {
          _status = _SaveStatus.saved;
          _failedDraft = null;
        });
      } else if (identical(entry.draft.token, _activeDraft?.token) &&
          entry.failed) {
        setState(() {
          _status = _SaveStatus.failed;
          _failedDraft = entry.draft;
        });
      }
    });
    final transitioning = ref.watch(accountTransitionProvider);
    final selectedIndex = _storedValues.indexOf(_feeling ?? '');
    final hasNote = _noteCtrl.text.trim().isNotEmpty;
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime.tryParse(widget.dateStr);
    final future = date != null && date.isAfter(today);
    final enabled = !future && !transitioning;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final prompt = date == today
        ? 'How did today feel?'
        : 'How did this day feel?';
    final status = switch (_status) {
      _SaveStatus.idle => selectedIndex >= 0 || hasNote ? 'Saved' : 'Optional',
      _SaveStatus.waiting || _SaveStatus.saving => 'Saving…',
      _SaveStatus.saved => selectedIndex >= 0 || hasNote ? 'Saved' : 'Optional',
      _SaveStatus.failed => 'Not saved. Your draft is here.',
    };

    final noteEditor = (!widget.alwaysShowNote && !_showNote) || !enabled
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: Spacing.stack),
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) _flushPendingNote();
              },
              child: AppTextField(
                controller: _noteCtrl,
                focusNode: _noteFocus,
                labelText: 'A note for yourself (optional)',
                hintText: 'What would you like to remember?',
                minLines: 1,
                maxLines: 3,
                onChanged: _onNoteChanged,
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.self_improvement_rounded,
              size: IconSize.inline,
              color: context.colors.textMedium,
            ),
            const SizedBox(width: Spacing.inline),
            Expanded(
              child: Text(
                future ? 'Daily check-in' : prompt,
                style: context.text.bodyStrong,
              ),
            ),
            if (enabled && !widget.alwaysShowNote)
              IconButton(
                tooltip: _showNote
                    ? 'Close reflection note'
                    : 'Edit reflection note',
                onPressed: _toggleNote,
                icon: Icon(
                  hasNote ? Icons.edit_note_rounded : Icons.edit_note_outlined,
                  size: IconSize.inline,
                  color: _showNote
                      ? context.colors.accentText
                      : context.colors.textMedium,
                ),
              ),
          ],
        ),
        if (future)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.stack),
            child: Text(
              'Check in when this day arrives.',
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final labelStyle = context.text.caption;
              final scaler = MediaQuery.textScalerOf(context);
              var minimumWidth = 0.0;
              for (final label in _labels) {
                final painter = TextPainter(
                  text: TextSpan(text: label, style: labelStyle),
                  textDirection: Directionality.of(context),
                  textScaler: scaler,
                )..layout();
                minimumWidth = math.max(minimumWidth, painter.width + 2);
                painter.dispose();
              }
              const gap = 8.0;
              final fittingColumns =
                  ((constraints.maxWidth + gap) / (minimumWidth + gap))
                      .floor()
                      .clamp(1, 5);
              final columns = fittingColumns == 4 ? 3 : fittingColumns;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: gap,
                runSpacing: gap,
                children: List.generate(5, (index) {
                  final selected = selectedIndex == index;
                  void select() => _selectFeeling(index);
                  return SizedBox(
                    width: width,
                    child: Semantics(
                      label: '${_labels[index]}, ${index + 1} of 5',
                      button: true,
                      selected: selected,
                      enabled: enabled,
                      onTap: enabled ? select : null,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: enabled ? select : null,
                          excludeFromSemantics: true,
                          borderRadius: BorderRadius.circular(Radii.micro),
                          child: ExcludeSemantics(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 56),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: reduceMotion
                                          ? Duration.zero
                                          : Motion.instant,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? context.colors.primary
                                            : context.colors.border,
                                        borderRadius: BorderRadius.circular(
                                          Radii.micro,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _labels[index],
                                      textAlign: TextAlign.center,
                                      style: labelStyle.copyWith(
                                        color: selected
                                            ? context.colors.accentText
                                            : context.colors.textMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        if (!widget.alwaysShowNote && !_showNote && hasNote)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.stack),
            child: InkWell(
              onTap: enabled ? _toggleNote : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _noteCtrl.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ),
            ),
          ),
        if (reduceMotion)
          noteEditor
        else
          AnimatedSize(
            duration: Motion.standard,
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: noteEditor,
          ),
        if (!future)
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                liveRegion: _status == _SaveStatus.failed,
                child: Text(
                  status,
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ),
              if (_status == _SaveStatus.failed)
                TextButton(
                  onPressed: enabled && _failedDraft != null
                      ? () => _enqueue(_failedDraft!)
                      : null,
                  child: const Text('Retry'),
                ),
              if (selectedIndex >= 0 || hasNote)
                TextButton(
                  onPressed: enabled ? _clearCheckIn : null,
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.textMedium,
                    textStyle: context.text.caption,
                  ),
                  child: const Text('Clear check-in'),
                ),
            ],
          ),
      ],
    );
  }
}
