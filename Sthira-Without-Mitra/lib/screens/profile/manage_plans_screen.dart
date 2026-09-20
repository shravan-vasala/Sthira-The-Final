import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../utils/meal_icons.dart';
import '../../utils/target_calculator.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/settings_row.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/target_estimate_sheet.dart';
import '../../theme/layout_insets.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class ManagePlansScreen extends ConsumerStatefulWidget {
  const ManagePlansScreen({super.key});
  @override
  ConsumerState<ManagePlansScreen> createState() => _ManagePlansScreenState();
}

class _ManagePlansScreenState extends ConsumerState<ManagePlansScreen> {
  final _dirtyEditors = <String, bool>{};
  bool _allowExit = false;
  bool _askingToLeave = false;
  bool _estimatingTargets = false;
  bool _savingTargets = false;
  String? _targetError;
  TargetEstimateInputs? _targetDraft;

  bool _ownsTargetDraft(int generation) =>
      mounted &&
      generation == ref.read(accountGenerationProvider) &&
      !ref.read(accountTransitionProvider) &&
      !ref.read(accountHydratingProvider);

  Future<void> _recalculateTargets() async {
    if (_estimatingTargets ||
        ref.read(accountTransitionProvider) ||
        ref.read(accountHydratingProvider)) {
      return;
    }
    final generation = ref.read(accountGenerationProvider);
    final profile = ref.read(profileProvider);
    setState(() {
      _estimatingTargets = true;
      _targetError = null;
    });
    try {
      final estimate = await showAppBottomSheet<TargetEstimate>(
        context: context,
        builder: (_) => TargetEstimateSheet(
          initialInputs:
              _targetDraft ??
              TargetEstimateInputs(
                heightCm: profile.height ?? TargetCalculator.defaultHeightCm,
                weightKg:
                    profile.currentWeight ?? TargetCalculator.defaultWeightKg,
                age: profile.age ?? TargetCalculator.defaultAge,
                gender: profile.gender ?? TargetCalculator.defaultGender,
                activityLevel: TargetCalculator.normalizeActivityLevel(
                  profile.activityLevel,
                ),
                goal: TargetCalculator.normalizeGoal(profile.primaryGoal),
              ),
          useKg: profile.useKg,
        ),
      );
      if (estimate == null || !_ownsTargetDraft(generation)) return;
      setState(() {
        _targetDraft = estimate.inputs;
        _savingTargets = true;
      });
      final latest = ref.read(profileProvider);
      final inputs = estimate.inputs;
      final targets = estimate.targets;
      await ref
          .read(profileProvider.notifier)
          .updateProfile(
            latest.copyWith(
              height: inputs.heightCm,
              currentWeight: inputs.weightKg,
              age: inputs.age,
              gender: inputs.gender,
              activityLevel: inputs.activityLevel,
              primaryGoal: inputs.goal,
              targetCalories: targets.calories,
              targetProteinG: targets.proteinG,
              targetCarbsG: targets.carbsG,
              targetFatG: targets.fatG,
            ),
          );
      if (!mounted || !_ownsTargetDraft(generation)) return;
      setState(() => _targetDraft = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Daily targets updated')));
    } catch (_) {
      if (_ownsTargetDraft(generation)) {
        setState(
          () => _targetError =
              'Could not save your targets. Tap Recalculate to review and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _estimatingTargets = false;
          _savingTargets = false;
        });
      }
    }
  }

  void _dirtyChanged(String type, bool dirty) {
    if (_dirtyEditors[type] == dirty) return;
    setState(() => _dirtyEditors[type] = dirty);
  }

  Future<void> _leave() async {
    if (_askingToLeave) return;
    _askingToLeave = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved plan changes?'),
        content: const Text(
          'Saved plans stay unchanged. Your open drafts will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _askingToLeave = false;
    if (discard == true && mounted) {
      setState(() => _allowExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(planRecordsUpdateProvider);
    final generation = ref.watch(accountGenerationProvider);
    ref.listen(accountGenerationProvider, (_, next) {
      _dirtyEditors.clear();
      _allowExit = false;
      _targetDraft = null;
      _targetError = null;
    });
    final transitioning =
        ref.watch(accountTransitionProvider) ||
        ref.watch(accountHydratingProvider);
    final profile = ref.watch(profileProvider);
    final workoutRepo = ref.watch(workoutRepoProvider);
    final mealRepo = ref.watch(mealRepoProvider);

    return PopScope(
      canPop:
          !_savingTargets &&
          (_allowExit || !_dirtyEditors.values.any((dirty) => dirty)),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_savingTargets) _leave();
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: context.colors.scaffoldBg,
          appBar: AppBar(
            title: const Text('Manage Plans'),
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.maybePop(context),
                  )
                : null,
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Workout Plans'),
                Tab(text: 'Meal Plans'),
                Tab(text: 'Meal Slots'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Active Plans Selection
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.screen,
                  vertical: Spacing.stack,
                ),
                color: context.colors.card,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Workout',
                            style: context.text.eyebrow.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                          const SizedBox(height: Spacing.textPair),
                          DropdownButton<String>(
                            value:
                                workoutRepo.getPlanKeys().contains(
                                  profile.activeWorkoutPlan,
                                )
                                ? profile.activeWorkoutPlan
                                : null,
                            isExpanded: true,
                            hint: Text('Select Plan', style: context.text.body),
                            items: workoutRepo
                                .getPlanKeys()
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k, style: context.text.body),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(profileProvider.notifier)
                                    .updateProfile(
                                      profile.copyWith(
                                        activeWorkoutPlan: val,
                                        clearPlanStart:
                                            val != profile.activeWorkoutPlan,
                                      ),
                                    );
                              }
                            },
                          ),
                          if (profile.planStartDate != null)
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(profileProvider.notifier)
                                    .updateProfile(
                                      profile.copyWith(clearPlanStart: true),
                                    );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(
                                'Reset phase progress',
                                style: context.text.micro.copyWith(
                                  color: context.colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Meals',
                            style: context.text.eyebrow.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                          const SizedBox(height: Spacing.textPair),
                          DropdownButton<String>(
                            value:
                                mealRepo.getPlanKeys().contains(
                                  profile.activeMealPlan,
                                )
                                ? profile.activeMealPlan
                                : null,
                            isExpanded: true,
                            hint: Text('Select Plan', style: context.text.body),
                            items: mealRepo
                                .getPlanKeys()
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k, style: context.text.body),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(profileProvider.notifier)
                                    .updateProfile(
                                      profile.copyWith(activeMealPlan: val),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.screen,
                  vertical: Spacing.stack,
                ),
                color: context.colors.card,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked =
                        constraints.maxWidth < 420 ||
                        MediaQuery.textScalerOf(context).scale(14) > 18;
                    final summary = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your daily targets',
                          style: context.text.eyebrow.copyWith(
                            color: context.colors.textMedium,
                          ),
                        ),
                        const SizedBox(height: Spacing.textPair),
                        Text(
                          '${profile.targetCalories} kcal (P:${profile.targetProteinG} C:${profile.targetCarbsG} F:${profile.targetFatG})',
                          style: context.text.body,
                        ),
                      ],
                    );
                    final recalculate = TextButton.icon(
                      onPressed: _estimatingTargets || transitioning
                          ? null
                          : _recalculateTargets,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: Text(_savingTargets ? 'Saving...' : 'Recalculate'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        backgroundColor: context.colors.primary.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flex(
                          direction: stacked ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: stacked
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            if (stacked) summary else Expanded(child: summary),
                            SizedBox(
                              width: stacked ? 0 : Spacing.stack,
                              height: stacked ? Spacing.stack : 0,
                            ),
                            recalculate,
                          ],
                        ),
                        if (_targetError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: Spacing.inline),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _targetError!,
                                style: context.text.caption.copyWith(
                                  color: context.colors.red,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PlanEditor(
                      key: ValueKey('workout-editor-$generation'),
                      type: 'workout',
                      onDirtyChanged: (value) =>
                          _dirtyChanged('workout', value),
                      getKeys: () => workoutRepo.getPlanKeys(),
                      getRawJson: (key) => workoutRepo.getRawPlanJson(key),
                      saveJson: (key, json) =>
                          workoutRepo.savePlanJson(key, json),
                    ),
                    _PlanEditor(
                      key: ValueKey('meal-editor-$generation'),
                      type: 'meal',
                      onDirtyChanged: (value) => _dirtyChanged('meal', value),
                      getKeys: () => mealRepo.getPlanKeys(),
                      getRawJson: (key) => mealRepo.getRawPlanJson(key),
                      saveJson: (key, json) => mealRepo.savePlanJson(key, json),
                    ),
                    const _MealSlotsEditor(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealSlotsEditor extends ConsumerStatefulWidget {
  const _MealSlotsEditor();
  @override
  ConsumerState<_MealSlotsEditor> createState() => _MealSlotsEditorState();
}

class _MealSlotsEditorState extends ConsumerState<_MealSlotsEditor> {
  Future<void> _deleteSlot(Map<String, dynamic> slot) async {
    final profile = ref.read(profileProvider);
    final updatedSlots = List<Map<String, dynamic>>.from(
      profile.customMealSlots,
    );
    updatedSlots.removeWhere((s) => s['id'] == slot['id']);
    await ref
        .read(profileProvider.notifier)
        .updateProfile(profile.copyWith(customMealSlots: updatedSlots));
  }

  void _editSlot(Map<String, dynamic> slot, int index) {
    final nameCtrl = TextEditingController(text: slot['name'] as String);
    String selectedEmoji = MealIcons.normalize(slot['emoji'] as String?);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Edit Meal Slot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              const Text('Icon:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MealIcons.options.map((opt) {
                  final isSelected = opt.id == selectedEmoji;
                  return GestureDetector(
                    onTap: () => setStateDialog(() => selectedEmoji = opt.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? context.colors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        opt.icon,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.textMedium,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: nameCtrl,
              builder: (context, value, child) {
                final isValid = value.text.trim().isNotEmpty;
                return ElevatedButton(
                  onPressed: isValid
                      ? () async {
                          final profile = ref.read(profileProvider);
                          final updatedSlots = List<Map<String, dynamic>>.from(
                            profile.customMealSlots,
                          );
                          updatedSlots[index] = {
                            ...slot,
                            'name': nameCtrl.text.trim(),
                            'emoji': selectedEmoji,
                          };
                          await ref
                              .read(profileProvider.notifier)
                              .updateProfile(
                                profile.copyWith(customMealSlots: updatedSlots),
                              );
                          if (context.mounted) Navigator.pop(ctx);
                        }
                      : null,
                  child: const Text('Save'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final slots = profile.customMealSlots;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        Spacing.screen,
        Spacing.section,
        Spacing.screen,
        shellScrollBottomPadding(context),
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isDefault = slot['isDefault'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: Spacing.stack),
          child: SettingsRow(
            icon: MealIcons.resolve(slot['emoji'] as String?),
            title: slot['name'] as String,
            subtitle: isDefault ? 'Default Slot' : 'Custom Recurring Slot',
            showChevron: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: context.colors.primary),
                  onPressed: () => _editSlot(slot, index),
                ),
                if (!isDefault)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: context.colors.red,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: context.colors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.sheet),
                          ),
                          title: Text(
                            'Delete Slot?',
                            style: context.text.screenTitle.copyWith(
                              color: context.colors.textDark,
                            ),
                          ),
                          content: Text(
                            'This will remove the slot from your daily template.\n\nAny meals you have already logged under this slot on past or current days will not be erased.',
                            style: context.text.body.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: context.text.body.copyWith(
                                  color: context.colors.textMedium,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _deleteSlot(slot);
                                if (context.mounted) Navigator.pop(ctx);
                              },
                              child: Text(
                                'Delete',
                                style: context.text.body.copyWith(
                                  color: context.colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanEditor extends ConsumerStatefulWidget {
  const _PlanEditor({
    super.key,
    required this.type,
    required this.getKeys,
    required this.getRawJson,
    required this.saveJson,
    required this.onDirtyChanged,
  });
  final String type;
  final List<String> Function() getKeys;
  final String? Function(String) getRawJson;
  final Future<void> Function(String, String) saveJson;
  final ValueChanged<bool> onDirtyChanged;
  @override
  ConsumerState<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<_PlanEditor>
    with AutomaticKeepAliveClientMixin {
  String? _selectedKey;
  final _controller = TextEditingController();
  final _name = TextEditingController();
  final _weeks = TextEditingController();
  String _savedJson = '';
  String _savedName = '';
  String _savedWeeks = '';
  bool _expert = false;
  bool _busy = false;
  bool _showJson = false;
  String? _error;
  late final int _generation;

  @override
  bool get wantKeepAlive => true;
  bool get _dirty =>
      _controller.text != _savedJson ||
      _name.text != _savedName ||
      _weeks.text != _savedWeeks;

  Map<String, dynamic>? get _draft {
    try {
      final json = jsonDecode(_controller.text);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _generation = ref.read(accountGenerationProvider);
    final profile = ref.read(profileProvider);
    final active = widget.type == 'workout'
        ? profile.activeWorkoutPlan
        : profile.activeMealPlan;
    final keys = widget.getKeys();
    if (keys.isNotEmpty) _load(keys.contains(active) ? active! : keys.first);
  }

  @override
  void didUpdateWidget(covariant _PlanEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final key = _selectedKey;
    if (!_busy &&
        !_dirty &&
        key != null &&
        widget.getRawJson(key) != _savedJson) {
      _load(key);
    }
  }

  void _load(String key) {
    _selectedKey = key;
    _controller.text = widget.getRawJson(key) ?? '';
    final data = _draft ?? {};
    _expert = data['source'] == 'seed' || data['source'] == 'public';
    _name.text = data['planName']?.toString() ?? key;
    final weeks = data['weeks'];
    _weeks.text =
        (weeks is List && weeks.isNotEmpty
                ? weeks.length
                : data['durationWeeks'] ?? '')
            .toString();
    _savedJson = _controller.text;
    _savedName = _name.text;
    _savedWeeks = _weeks.text;
    _error = null;
  }

  void _changed() {
    setState(() => _error = null);
    widget.onDirtyChanged(_dirty);
  }

  void _checkScope() {
    if (!mounted ||
        ref.read(accountGenerationProvider) != _generation ||
        ref.read(accountTransitionProvider)) {
      throw StateError(
        'Your account changed. Reopen Manage Plans to continue.',
      );
    }
  }

  Future<bool> _mayDiscard() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard unsaved changes?'),
            content: const Text('Your saved plan will stay unchanged.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ==
        true;
  }

  Future<void> _select(String key) async {
    if (_busy || !await _mayDiscard() || !mounted) return;
    try {
      _checkScope();
      setState(() => _load(key));
      widget.onDirtyChanged(false);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message.toString());
    }
  }

  Future<void> _import() async {
    if (_busy || !await _mayDiscard() || !mounted) return;
    setState(() {
      _selectedKey = null;
      _expert = false;
      _showJson = true;
      _controller.clear();
      _name.clear();
      _weeks.text = '';
      _savedJson = '';
      _savedName = '';
      _savedWeeks = '';
      _error = null;
    });
    widget.onDirtyChanged(false);
  }

  Map<String, dynamic> _dataForSave() {
    final data = _draft;
    if (data == null)
      throw const FormatException('Paste a valid plan JSON object first.');
    final name = _name.text.trim();
    if (name.isEmpty) throw const FormatException('Enter a plan name.');
    data['planName'] = name;
    data['source'] = 'user';
    data.remove('seedVersion');
    if (widget.type == 'workout') {
      final existing = data['weeks'];
      if (existing != null && existing is! List) {
        throw const FormatException('The weeks field must be an array.');
      }
      final lengthText = _weeks.text.trim();
      if (lengthText.isEmpty && (existing is! List || existing.isEmpty)) {
        data.remove('durationWeeks');
        data.remove('weeks');
        return data;
      }
      final count = int.tryParse(lengthText);
      if (count == null || count < 1 || count > 104) {
        throw const FormatException('Choose 1 to 104 whole weeks.');
      }
      if (existing is List && existing.isNotEmpty) {
        // Explicitly requested extra weeks repeat the final schedule. They are
        // editable; no exercise, load or progression target is invented.
        final weeks = List<dynamic>.from(existing);
        while (weeks.length < count) {
          final copy =
              jsonDecode(jsonEncode(weeks.last)) as Map<String, dynamic>;
          for (final day in copy['days'] as List? ?? const []) {
            for (final section in day['sections'] as List? ?? const []) {
              for (final exercise
                  in section['exercises'] as List? ?? const []) {
                (exercise as Map).remove('instanceId');
              }
            }
          }
          weeks.add(copy);
        }
        final resized = weeks.take(count).toList();
        for (var i = 0; i < resized.length; i++) {
          resized[i]['weekNumber'] = i + 1;
        }
        data['weeks'] = resized;
        data.remove('durationWeeks');
      } else {
        data['durationWeeks'] = count;
        data.remove('weeks');
      }
    }
    return data;
  }

  Future<void> _activate(String key) async {
    _checkScope();
    final profile = ref.read(profileProvider);
    await ref
        .read(profileProvider.notifier)
        .updateProfile(
          widget.type == 'workout'
              ? profile.copyWith(
                  activeWorkoutPlan: key,
                  clearPlanStart: profile.activeWorkoutPlan != key,
                )
              : profile.copyWith(activeMealPlan: key),
        );
    _checkScope();
  }

  Future<void> _save({bool activate = false}) async {
    if (_busy || _expert) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _checkScope();
      final data = _dataForSave();
      final key = data['planName'] as String;
      if (key != _selectedKey && widget.getKeys().contains(key)) {
        throw const FormatException(
          'That plan name already exists. Choose another name.',
        );
      }
      if (_dirty &&
          key == _selectedKey &&
          widget.getRawJson(key) != _savedJson) {
        throw const FormatException(
          'This plan changed elsewhere. Change the name to save your draft as a new plan.',
        );
      }
      // A changed name saves a new plan. Existing plans and their history stay available.
      await widget.saveJson(key, jsonEncode(data));
      _checkScope();
      if (activate) await _activate(key);
      setState(() => _load(key));
      widget.onDirtyChanged(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activate ? 'Plan saved and selected' : 'Plan saved'),
        ),
      );
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error
              .toString()
              .replaceAll('FormatException: ', '')
              .replaceAll('Bad state: ', ''),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _customize() async {
    if (_busy || _selectedKey == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _checkScope();
      final data = _draft!;
      final origin = data['basedOnPlanName'] ?? data['planName'];
      final base = data['planName'].toString();
      var key = '$base (Custom)';
      for (var i = 2; widget.getKeys().contains(key); i++) {
        key = '$base (Custom $i)';
      }
      data['planName'] = key;
      data['basedOnPlanName'] = origin;
      data['source'] = 'user';
      data.remove('seedVersion');
      await widget.saveJson(key, jsonEncode(data));
      _checkScope();
      await _activate(key);
      setState(() => _load(key));
      widget.onDirtyChanged(false);
    } catch (error) {
      if (mounted)
        setState(() => _error = 'Could not customize this plan: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _weeks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final keys = widget.getKeys();
    final data = _draft;
    final explicitWeeks =
        data?['weeks'] is List && (data!['weeks'] as List).isNotEmpty;
    final origin = data?['basedOnPlanName'];
    final meals = data?['meals'];
    final mealCalories = widget.type == 'meal' && meals is List
        ? meals.fold<num>(
            0,
            (sum, meal) =>
                sum +
                (meal is Map && meal['calories'] is num
                    ? meal['calories'] as num
                    : 0),
          )
        : null;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Spacing.screen,
        Spacing.screen,
        Spacing.screen,
        shellScrollBottomPadding(context),
      ),
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('${widget.type}-plan-selector-$_selectedKey'),
          initialValue: keys.contains(_selectedKey) ? _selectedKey : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Plan'),
          hint: const Text('Select or import a plan'),
          items: keys
              .map(
                (key) => DropdownMenuItem(
                  value: key,
                  child: Text(
                    key,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _busy
              ? null
              : (key) {
                  if (key != null) _select(key);
                },
        ),
        const SizedBox(height: Spacing.stack),
        Wrap(
          spacing: Spacing.inline,
          runSpacing: Spacing.inline,
          children: [
            if (_expert)
              FilledButton.icon(
                onPressed: _busy ? null : _customize,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Customize'),
              ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Import JSON'),
            ),
          ],
        ),
        if (_selectedKey != null) ...[
          const SizedBox(height: Spacing.stack),
          Text(
            _expert
                ? 'Expert-suggested plan'
                : origin != null
                ? 'Your custom plan · Based on $origin'
                : 'Your custom plan',
            style: context.text.bodyStrong,
          ),
          const SizedBox(height: Spacing.textPair),
          Text(
            _expert
                ? 'Customize creates your own editable plan and keeps the expert original available.'
                : 'Your changes stay yours when expert plans are updated.',
            style: context.text.caption,
          ),
        ],
        if (mealCalories != null && data != null) ...[
          const SizedBox(height: Spacing.stack),
          Text(
            'Suggested plan total: ${mealCalories.round()} kcal',
            style: context.text.bodyStrong,
          ),
          Text(
            'Your personal daily target is shown above. The plan total does not change that target.',
            style: context.text.caption,
          ),
        ],
        if (!_expert) ...[
          const SizedBox(height: Spacing.stack),
          TextField(
            key: ValueKey('${widget.type}-plan-name'),
            controller: _name,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Plan name'),
            onChanged: (_) => _changed(),
          ),
        ],
        if (widget.type == 'workout' && data != null) ...[
          const SizedBox(height: Spacing.stack),
          TextField(
            key: const ValueKey('program-weeks'),
            controller: _weeks,
            readOnly: _expert,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Program length (weeks)',
              helperText: _expert
                  ? (_weeks.text.isEmpty
                        ? 'No program length specified.'
                        : 'Customize to change the program length.')
                  : 'Enter 1-104 weeks, or leave blank for an ongoing routine.',
              helperMaxLines: 3,
            ),
            onChanged: (_) => _changed(),
          ),
          const SizedBox(height: Spacing.textPair),
          Text(
            explicitWeeks
                ? 'Each week has its own schedule. Added weeks repeat the final week; edit their exercises in JSON. Reducing the length removes the final weeks from this plan.'
                : _weeks.text.trim().isEmpty
                ? 'This weekly routine repeats until you choose another plan.'
                : 'This weekly routine repeats for the chosen number of weeks.',
            style: context.text.caption,
          ),
        ],
        const SizedBox(height: Spacing.stack),
        TextButton.icon(
          onPressed: () => setState(() => _showJson = !_showJson),
          icon: Icon(_showJson ? Icons.expand_less : Icons.code),
          label: Text(
            _showJson
                ? 'Hide JSON'
                : _expert
                ? 'View expert plan JSON'
                : 'Edit plan JSON',
          ),
        ),
        if (_showJson)
          TextField(
            key: ValueKey('${widget.type}-plan-json'),
            controller: _controller,
            readOnly: _expert || _busy,
            minLines: 10,
            maxLines: null,
            style: context.text.micro,
            decoration: const InputDecoration(
              hintText: 'Paste the complete plan JSON here.',
            ),
            onChanged: (_) {
              final parsed = _draft;
              if (parsed != null) {
                _name.text = parsed['planName']?.toString() ?? '';
                final weeks = parsed['weeks'];
                _weeks.text =
                    (weeks is List && weeks.isNotEmpty
                            ? weeks.length
                            : parsed['durationWeeks'] ?? '')
                        .toString();
              }
              _changed();
            },
          ),
        if (!_expert) ...[
          const SizedBox(height: Spacing.stack),
          Wrap(
            spacing: Spacing.inline,
            runSpacing: Spacing.inline,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => _save(),
                child: const Text('Save'),
              ),
              FilledButton(
                onPressed: _busy ? null : () => _save(activate: true),
                child: Text(_busy ? 'Saving…' : 'Save and use'),
              ),
            ],
          ),
        ],
        if (_dirty)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.inline),
            child: Text('Unsaved changes', style: context.text.caption),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.stack),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: context.text.caption.copyWith(color: context.colors.red),
              ),
            ),
          ),
      ],
    );
  }
}
