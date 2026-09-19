import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../models/habit.dart';
import '../../../utils/habit_icons.dart';
import '../../../utils/target_calculator.dart';
import '../../../widgets/section_header.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class YourPlanPage extends StatefulWidget {
  final double initialCalories;
  final TargetMacros? initialMacros;
  final double? heightCm;
  final double? weightKg;
  final List<String> selectedHabitIds;
  final bool isManuallyEdited;
  final void Function(double, bool) onCaloriesChanged;
  final ValueChanged<TargetMacros?>? onMacrosChanged;
  final void Function(String id, bool selected) onHabitToggled;

  const YourPlanPage({
    super.key,
    required this.initialCalories,
    this.initialMacros,
    required this.heightCm,
    this.weightKg,
    required this.selectedHabitIds,
    required this.isManuallyEdited,
    required this.onCaloriesChanged,
    this.onMacrosChanged,
    required this.onHabitToggled,
  });

  @override
  State<YourPlanPage> createState() => _YourPlanPageState();
}

class _YourPlanPageState extends State<YourPlanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late double _currentCalories;
  TargetMacros? _macroPreview;
  bool _usedSuggestion = false;

  @override
  void initState() {
    super.initState();
    _currentCalories = widget.initialCalories;
    _staggerController = AnimationController(
      vsync: this,
      duration: Motion.deliberate,
    );
    _staggerController.forward();
    _updateMacroPreview();
    final macros = _getDynamicMacrosForCalories(_currentCalories);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMacrosChanged?.call(macros);
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(YourPlanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCalories != oldWidget.initialCalories &&
        widget.initialCalories != _currentCalories) {
      _currentCalories = widget.initialCalories;
      _usedSuggestion = false;
    }
    if (widget.heightCm != oldWidget.heightCm ||
        widget.weightKg != oldWidget.weightKg) {
      _updateMacroPreview();
      final macros = _getDynamicMacrosForCalories(_currentCalories);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onMacrosChanged?.call(macros);
      });
    }
  }

  void _updateMacroPreview() {
    _macroPreview = TargetCalculator.calculate(
      heightCm: widget.heightCm,
      weightKg: widget.weightKg,
      age: null,
      gender: null,
      goal: 'Maintain',
      activityLevel: null,
    );
  }

  void _suggestMacros() {
    if (_macroPreview != null) {
      setState(() {
        _usedSuggestion = true;
        _currentCalories = _macroPreview!.calories.toDouble();
        widget.onCaloriesChanged(_currentCalories, false);
        widget.onMacrosChanged?.call(_macroPreview);
      });
    }
  }

  Widget _buildAnimEntrance(int index, Widget child) {
    return Builder(
      builder: (context) {
        if (MediaQuery.disableAnimationsOf(context)) {
          return child;
        }
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
      },
    );
  }

  TargetMacros? _getDynamicMacrosForCalories(double cal) {
    if (!_usedSuggestion &&
        widget.initialMacros != null &&
        cal.round() == widget.initialMacros!.calories)
      return widget.initialMacros;
    if (_macroPreview == null) return null;
    return TargetCalculator.rebalanceForCalories(
      cal.round(),
      _usedSuggestion ? _macroPreview! : widget.initialMacros ?? _macroPreview!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicMacros = _getDynamicMacrosForCalories(_currentCalories);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildAnimEntrance(
            0,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.track_changes_outlined,
                  size: 48,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Daily targets',
                  style: context.text.display.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildAnimEntrance(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _usedSuggestion
                      ? 'Suggested estimate'
                      : widget.isManuallyEdited
                      ? 'Your current target'
                      : 'Expert-suggested starting target',
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentCalories.round()} kcal',
                  style: context.text.metric.copyWith(
                    color: context.colors.primary,
                  ),
                ),
                if (_macroPreview != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: ActionChip(
                      label: const Text('Suggest for me'),
                      avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                      backgroundColor: context.colors.primary.withValues(
                        alpha: 0.15,
                      ),
                      labelStyle: context.text.body.copyWith(
                        color: context.colors.primary,
                      ),
                      side: BorderSide.none,
                      onPressed: _suggestMacros,
                    ),
                  ),
                const SizedBox(height: 12),
                Slider(
                  value: _currentCalories.clamp(1200, 4000).toDouble(),
                  min: 1200,
                  max: 4000,
                  divisions: (4000 - 1200) ~/ 50,
                  onChanged: (v) {
                    setState(() {
                      _currentCalories = v;
                      _usedSuggestion = false;
                    });
                    widget.onCaloriesChanged(v, true);
                    final dynamicMacros = _getDynamicMacrosForCalories(v);
                    if (dynamicMacros != null) {
                      widget.onMacrosChanged?.call(dynamicMacros);
                    }
                  },
                ),
                if (dynamicMacros != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MacroChip(
                              value: dynamicMacros.proteinG,
                              label: 'P',
                            ),
                            _MacroChip(value: dynamicMacros.carbsG, label: 'C'),
                            _MacroChip(value: dynamicMacros.fatG, label: 'F'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (ctx) {
                            final List<String> defaults = [];
                            if (widget.heightCm == null) defaults.add('Height');
                            if (widget.weightKg == null) defaults.add('Weight');
                            defaults.add('age 29');
                            defaults.add('female sex');
                            defaults.add('sedentary activity');
                            defaults.add('maintenance goal');

                            if (defaults.isEmpty) {
                              return const SizedBox();
                            }
                            return Text(
                              'Suggest for me uses ${defaults.join(', ')}. Targets are editable and separate from the meal plan portions.',
                              style: context.text.micro.copyWith(
                                color: context.colors.textMedium,
                              ),
                              textAlign: TextAlign.left,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildAnimEntrance(
            2,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Select Habits'),
                const SizedBox(height: 16),
                ...Habit.defaults.map((habit) {
                  final selected = widget.selectedHabitIds.contains(habit.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HabitTile(
                      habit: habit,
                      selected: selected,
                      onToggle: (s) => widget.onHabitToggled(habit.id, s),
                    ),
                  );
                }),
                if (widget.selectedHabitIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Please select at least one habit to track.',
                      style: context.text.body.copyWith(
                        color: context.colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final int value;
  final String label;

  const _MacroChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label ${value}g',
        style: context.text.caption.copyWith(color: context.colors.primary),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final bool selected;
  final ValueChanged<bool> onToggle;

  const _HabitTile({
    required this.habit,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.disableAnimationsOf(context);

    Widget tile = AnimatedContainer(
      duration: disableAnim ? Duration.zero : Motion.standard,
      curve: Motion.enter,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(20),
        border: selected
            ? Border.all(color: context.colors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              HabitIcons.resolve(habit.icon),
              color: selected
                  ? context.colors.primary
                  : context.colors.textMedium,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              habit.name,
              style: context.text.cardTitle.copyWith(
                color: context.colors.textDark,
              ),
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: context.colors.primary),
        ],
      ),
    );

    if (!disableAnim) {
      tile = tile
          .animate(target: selected ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(0.97, 0.97),
            duration: Motion.instant,
            curve: Motion.enter,
          )
          .then()
          .scale(
            begin: const Offset(0.97, 0.97),
            end: const Offset(1, 1),
            duration: Motion.standard,
            curve: Motion.enter,
          )
          .shimmer(
            duration: Motion.deliberate,
            color: context.colors.surface.withValues(alpha: 0.2),
          );
    }

    return GestureDetector(
      onTap: () => onToggle(!selected),
      behavior: HitTestBehavior.opaque,
      child: tile,
    );
  }
}
