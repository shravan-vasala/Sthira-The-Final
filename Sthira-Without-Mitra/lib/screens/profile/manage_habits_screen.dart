import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/habit.dart';
import '../../utils/habit_icons.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/layout_insets.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/settings_row.dart';

class ManageHabitsScreen extends ConsumerStatefulWidget {
  const ManageHabitsScreen({super.key});

  @override
  ConsumerState<ManageHabitsScreen> createState() => _ManageHabitsScreenState();
}

class _ManageHabitsScreenState extends ConsumerState<ManageHabitsScreen> {
  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(allHabitsProvider);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Manage Habits'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_rounded,
              color: context.colors.primary,
            ),
            tooltip: 'Remind me daily',
            onPressed: () => context.go('/profile/reminders'),
          ),
        ],
      ),
      body: habits.isEmpty
          ? Center(
              child: Text(
                'No habits found. Add one!',
                style: context.text.body.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: EdgeInsets.fromLTRB(
                Spacing.screen,
                Spacing.section,
                Spacing.screen,
                // Leave room for Add Habit above the measured shell footer.
                shellScrollBottomPadding(context) + Spacing.major * 3,
              ),
              itemCount: habits.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                final list = List<Habit>.from(habits);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                ref.read(habitRepoProvider).reorderHabits(list).then((_) {
                  ref.invalidate(allHabitsProvider);
                  ref.invalidate(habitsProvider);
                });
              },
              itemBuilder: (context, index) {
                final habit = habits[index];
                return _HabitListTile(key: ValueKey(habit.id), habit: habit);
              },
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: shellFloatingActionBottomPadding(context) + Spacing.block,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showEditorDialog(context, ref, null),
          backgroundColor: context.colors.primary,
          icon: Icon(Icons.add_rounded, color: context.colors.onPrimary),
          label: Text(
            'Add Habit',
            style: context.text.body.copyWith(color: context.colors.onPrimary),
          ),
        ),
      ),
    );
  }

  void _showEditorDialog(BuildContext context, WidgetRef ref, Habit? habit) {
    showAppBottomSheet(
      context: context,
      builder: (ctx) => _HabitEditorDialog(habit: habit),
    );
  }
}

class _HabitListTile extends ConsumerWidget {
  final Habit habit;
  const _HabitListTile({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: Spacing.stack),
      child: SettingsRow(
        icon: HabitIcons.resolve(habit.icon),
        title: habit.name,
        subtitle: _getTypeDescription(habit),
        showChevron: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz_rounded,
                color: context.colors.textMedium,
              ),
              color: context.colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              onSelected: (val) {
                if (val == 'edit') {
                  showAppBottomSheet(
                    context: context,
                    builder: (ctx) => _HabitEditorDialog(habit: habit),
                  );
                } else if (val == 'delete') {
                  _showDeleteConfirm(context, ref);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: context.text.body),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: context.text.body.copyWith(
                      color: context.colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: Spacing.inline),
            Icon(Icons.drag_handle_rounded, color: context.colors.textMedium),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    final generation = ref.read(accountGenerationProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.sheet),
              ),
              title: Text(
                'Delete Habit?',
                style: context.text.screenTitle.copyWith(
                  color: context.colors.textDark,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this habit? History will be kept for past days, but it won\'t appear anymore.',
                style: context.text.body.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: context.text.body.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          if (ref.read(accountGenerationProvider) !=
                                  generation ||
                              ref.read(accountTransitionProvider)) {
                            Navigator.pop(ctx);
                            return;
                          }
                          setState(() => isDeleting = true);
                          try {
                            await ref
                                .read(habitRepoProvider)
                                .deleteHabit(habit.id);
                            if (!ctx.mounted) return;
                            ref.invalidate(habitsProvider);
                            Navigator.pop(ctx);
                          } catch (e) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Delete',
                          style: context.text.body.copyWith(
                            color: context.colors.red,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getTypeDescription(Habit h) {
    switch (h.type) {
      case HabitType.checkbox:
        if (h.unit.isNotEmpty && h.target > 0) {
          final t = h.target == h.target.roundToDouble()
              ? h.target.toInt().toString()
              : h.target.toString();
          return 'Tap once · Goal: $t ${h.unit}';
        }
        return 'Tap once to complete';
      case HabitType.counter:
        return 'Counter (Target: ${h.target} ${h.unit})';
      case HabitType.autoSteps:
        return 'Auto from Steps (Target: ${h.target})';
      case HabitType.autoSleep:
        return 'From sleep log (Target: ${h.target} hrs)';
      case HabitType.autoFromScreenTime:
        return 'From screen time (Target: ${h.target} mins)';
      case HabitType.timer:
        return 'Timer (Target: ${h.target} mins)';
    }
  }
}

class _HabitEditorDialog extends ConsumerStatefulWidget {
  final Habit? habit;
  const _HabitEditorDialog({this.habit});

  @override
  ConsumerState<_HabitEditorDialog> createState() => _HabitEditorDialogState();
}

class _HabitEditorDialogState extends ConsumerState<_HabitEditorDialog> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _stepCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();

  String? _targetError;
  String? _stepError;
  String? _nameError;

  String _selectedIcon = 'check';
  HabitType _type = HabitType.checkbox;
  bool _isWaterHabit = false;
  List<int>? _activeDays;
  bool _isSaving = false;
  late final int _accountGeneration;

  @override
  void initState() {
    super.initState();
    _accountGeneration = ref.read(accountGenerationProvider);
    if (widget.habit != null) {
      final h = widget.habit!;
      _isWaterHabit = h.id == 'water';
      _nameCtrl.text = h.name;
      _selectedIcon = HabitIcons.normalize(h.icon);
      _type = h.type;
      _targetCtrl.text = h.target.toString();
      _stepCtrl.text = h.step.toString();
      _unitCtrl.text = h.unit;
      _activeDays = h.activeDays != null ? List<int>.from(h.activeDays!) : null;
    } else {
      _targetCtrl.text = '1';
      _stepCtrl.text = '1';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _stepCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _syncWaterNameFromGoal() {
    if (!_isWaterHabit) return;
    final currentName = _nameCtrl.text.trim();
    if (currentName.isNotEmpty &&
        !currentName.startsWith('Drink ') &&
        !currentName.endsWith(' of water')) {
      // User has customized the name, don't overwrite it
      return;
    }

    final target = double.tryParse(_targetCtrl.text) ?? 3.0;
    final unit = _unitCtrl.text.trim().isEmpty ? 'L' : _unitCtrl.text.trim();
    final targetLabel = target == target.roundToDouble()
        ? target.toInt().toString()
        : target.toString();
    _nameCtrl.text = 'Drink $targetLabel $unit of water';
  }

  Future<void> _submit() async {
    if (_isSaving ||
        ref.read(accountGenerationProvider) != _accountGeneration ||
        ref.read(accountTransitionProvider))
      return;

    var name = _nameCtrl.text.trim();
    bool hasError = false;

    if (name.isEmpty && !_isWaterHabit) {
      setState(() => _nameError = 'Name is required');
      hasError = true;
    } else {
      setState(() => _nameError = null);
    }

    var target = 1.0;
    var step = 1.0;
    var unit = _unitCtrl.text.trim();

    if (_showGoalFields) {
      final pTarget = double.tryParse(_targetCtrl.text);
      if (pTarget == null || !pTarget.isFinite || pTarget <= 0) {
        setState(() => _targetError = 'Must be > 0');
        hasError = true;
      } else {
        target = pTarget;
        setState(() => _targetError = null);
      }
    } else {
      setState(() => _targetError = null);
    }

    if (_type == HabitType.counter && !_isWaterHabit) {
      final pStep = double.tryParse(_stepCtrl.text);
      if (pStep == null || !pStep.isFinite || pStep <= 0) {
        setState(() => _stepError = 'Must be > 0');
        hasError = true;
      } else {
        step = pStep;
        setState(() => _stepError = null);
      }
    } else {
      setState(() => _stepError = null);
    }

    if (hasError) return;

    // Water: always checkbox with customizable daily goal
    var type = _type;
    if (_isWaterHabit) {
      type = HabitType.checkbox;
      if (unit.isEmpty) unit = 'L';
      if (target <= 0) target = 3.0; // Fallback
      final targetLabel = target == target.roundToDouble()
          ? target.toInt().toString()
          : target.toString();
      name = 'Drink $targetLabel $unit of water';
    }

    final isNew = widget.habit == null;
    final id = isNew
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : widget.habit!.id;

    final updated = Habit(
      id: id,
      name: name,
      icon: HabitIcons.normalize(_selectedIcon),
      type: type,
      target: target,
      initialCreatedAt: widget.habit?.createdAt ?? ref.read(clockProvider),
      goalDirection:
          widget.habit?.goalDirection ??
          (_type == HabitType.autoFromScreenTime
              ? GoalDirection.atMost
              : GoalDirection.atLeast),
      activeDays: (_activeDays != null && _activeDays!.isEmpty)
          ? []
          : _activeDays,
      step: step,
      unit: unit,
      order: isNew ? ref.read(allHabitsProvider).length : widget.habit!.order,
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(habitRepoProvider).saveHabit(updated);
      if (!mounted) return;
      ref.invalidate(allHabitsProvider);
      ref.invalidate(habitsProvider);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  bool get _showGoalFields => _isWaterHabit || _type != HabitType.checkbox;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: widget.habit == null ? 'Add Habit' : 'Edit Habit',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.stack),
          TextField(
            controller: _nameCtrl,
            style: context.text.body.copyWith(color: context.colors.textDark),
            decoration: InputDecoration(
              labelText: _isWaterHabit ? 'Water habit name' : 'Habit name',
              errorText: _nameError,
              hintText: 'e.g. Meditate 10 min',
              filled: true,
              fillColor: context.colors.inputFill,
              labelStyle: context.text.body.copyWith(
                color: context.colors.textMedium,
              ),
              hintStyle: context.text.body.copyWith(
                color: context.colors.textLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_isWaterHabit) ...[
            const SizedBox(height: Spacing.inline),
            Text(
              'Daily water goal',
              style: context.text.eyebrow.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            const SizedBox(height: Spacing.inline),
            Text(
              'Tap once on Home to mark it done. Change how much you aim for below.',
              style: context.text.caption.copyWith(
                color: context.colors.textLight,
              ),
            ),
          ],
          const SizedBox(height: Spacing.block),
          Text(
            'Icon',
            style: context.text.eyebrow.copyWith(
              color: context.colors.textMedium,
            ),
          ),
          const SizedBox(height: Spacing.stack),
          Wrap(
            spacing: Spacing.inline,
            runSpacing: Spacing.inline,
            children: HabitIcons.options.map((opt) {
              final isSelected = opt.id == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = opt.id),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Icon(
                    opt.icon,
                    size: IconSize.row,
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.textMedium,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.section),
          Text(
            'Active days',
            style: context.text.eyebrow.copyWith(
              color: context.colors.textMedium,
            ),
          ),
          const SizedBox(height: Spacing.textPair),
          Text(
            'Leave all days unselected to pause this habit. Select all days to run every day.',
            style: context.text.caption.copyWith(
              color: context.colors.textMedium,
            ),
          ),
          const SizedBox(height: Spacing.stack),
          Wrap(
            spacing: Spacing.inline,
            runSpacing: Spacing.inline,
            children: List.generate(7, (index) {
              final day = index + 1;
              const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              const fullLabels = [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ];
              final selected =
                  _activeDays == null || _activeDays!.contains(day);
              return Semantics(
                label: fullLabels[index],
                selected: selected,
                child: FilterChip(
                  label: Text(labels[index]),
                  selected: selected,
                  onSelected: _isSaving
                      ? null
                      : (_) => setState(() {
                          _activeDays ??= [1, 2, 3, 4, 5, 6, 7];
                          if (selected) {
                            _activeDays!.remove(day);
                          } else {
                            _activeDays!.add(day);
                            if (_activeDays!.length == 7) _activeDays = null;
                          }
                        }),
                ),
              );
            }),
          ),
          if (!_isWaterHabit) ...[
            const SizedBox(height: Spacing.section),
            DropdownButtonFormField<HabitType>(
              initialValue: _type,
              isExpanded: true,
              selectedItemBuilder: (context) => [
                for (final label in [
                  'Checkbox',
                  'Counter',
                  'Steps',
                  'Sleep',
                  'Screen time',
                  'Timer',
                ])
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              dropdownColor: context.colors.card,
              style: context.text.body.copyWith(color: context.colors.textDark),
              iconEnabledColor: context.colors.textMedium,
              decoration: InputDecoration(
                labelText: 'Type',
                labelStyle: context.text.body.copyWith(
                  color: context.colors.textMedium,
                ),
                filled: true,
                fillColor: context.colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: HabitType.checkbox,
                  child: Text(
                    'Checkbox (Tap once)',
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: HabitType.counter,
                  child: Text(
                    'Counter (+ / −)',
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: HabitType.autoSteps,
                  child: Text(
                    'Auto from Steps',
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: HabitType.autoSleep,
                  child: Text(
                    'Auto from Sleep',
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: HabitType.autoFromScreenTime,
                  child: Text(
                    'Auto from Screen Time',
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: HabitType.timer,
                  child: Text(
                    'Timer (Countdown)',
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
          ],
          if (_showGoalFields) ...[
            const SizedBox(height: Spacing.block),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetCtrl,
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                    decoration: InputDecoration(
                      labelText: _isWaterHabit ? 'Amount' : 'Target',
                      errorText: _targetError,
                      filled: true,
                      fillColor: context.colors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      if (_isWaterHabit) {
                        setState(_syncWaterNameFromGoal);
                      }
                    },
                  ),
                ),
                const SizedBox(width: Spacing.stack),
                Expanded(
                  child: TextField(
                    controller: _unitCtrl,
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                    decoration: InputDecoration(
                      labelText: _isWaterHabit ? 'Unit' : 'Unit (e.g. L)',
                      filled: true,
                      fillColor: context.colors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      if (_isWaterHabit) {
                        setState(_syncWaterNameFromGoal);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_isWaterHabit) ...[
              const SizedBox(height: 12),
              Text(
                _nameCtrl.text,
                style: context.text.body.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ],
          ],
          if (_type == HabitType.counter && !_isWaterHabit) ...[
            const SizedBox(height: Spacing.stack),
            TextField(
              controller: _stepCtrl,
              style: context.text.body.copyWith(color: context.colors.textDark),
              decoration: InputDecoration(
                labelText: 'Increment step (e.g. 0.25)',
                errorText: _stepError,
                filled: true,
                fillColor: context.colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
          const SizedBox(height: Spacing.major),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              onPressed: _isSaving ? null : _submit,
              isLoading: _isSaving,
              label: _isSaving ? 'Saving...' : 'Save',
            ),
          ),
          const SizedBox(height: Spacing.section),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: context.text.body.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
