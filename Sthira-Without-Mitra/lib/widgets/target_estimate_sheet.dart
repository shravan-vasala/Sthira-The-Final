import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/target_calculator.dart';
import 'app_bottom_sheet.dart';
import 'primary_button.dart';

/// Edits a draft only. The caller decides when and where accepted targets save.
class TargetEstimateSheet extends StatefulWidget {
  const TargetEstimateSheet({
    super.key,
    required this.initialInputs,
    this.useKg = true,
  });

  final TargetEstimateInputs initialInputs;
  final bool useKg;

  @override
  State<TargetEstimateSheet> createState() => _TargetEstimateSheetState();
}

class _TargetEstimateSheetState extends State<TargetEstimateSheet> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final String _initialHeightText;
  late final String _initialWeightText;
  late String _gender;
  late String _activity;
  late String _goal;

  String _number(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  void initState() {
    super.initState();
    final inputs = widget.initialInputs;
    _age = TextEditingController(text: inputs.age.toString());
    _initialHeightText = _number(inputs.heightCm);
    _initialWeightText = _number(
      inputs.weightKg * (widget.useKg ? 1 : 2.20462),
    );
    _height = TextEditingController(text: _initialHeightText);
    _weight = TextEditingController(text: _initialWeightText);
    _gender = const ['M', 'MALE'].contains(inputs.gender.toUpperCase())
        ? 'M'
        : 'F';
    _activity = TargetCalculator.normalizeActivityLevel(inputs.activityLevel);
    _goal = TargetCalculator.normalizeGoal(inputs.goal);
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? _decimal(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  double? get _heightCm => _height.text == _initialHeightText
      ? widget.initialInputs.heightCm
      : _decimal(_height.text);

  double? get _weightKg {
    if (_weight.text == _initialWeightText) {
      return widget.initialInputs.weightKg;
    }
    final value = _decimal(_weight.text);
    return value == null ? null : value / (widget.useKg ? 1 : 2.20462);
  }

  String? get _ageError {
    final value = int.tryParse(_age.text.trim());
    return value == null || value < 18 || value > 100
        ? 'Enter an age from 18 to 100'
        : null;
  }

  String? get _heightError {
    final value = _heightCm;
    return value == null || !value.isFinite || value < 100 || value > 230
        ? 'Enter a height from 100 to 230 cm'
        : null;
  }

  String? get _weightError {
    final value = _weightKg;
    return value == null || !value.isFinite || value < 30 || value > 200
        ? (widget.useKg
              ? 'Enter a weight from 30 to 200 kg'
              : 'Enter a weight from 66.14 to 440.92 lb')
        : null;
  }

  TargetEstimate? get _estimate {
    if (_ageError != null || _heightError != null || _weightError != null) {
      return null;
    }
    try {
      return TargetCalculator.estimate(
        TargetEstimateInputs(
          heightCm: _heightCm!,
          weightKg: _weightKg!,
          age: int.parse(_age.text.trim()),
          gender: _gender,
          activityLevel: _activity,
          goal: _goal,
        ),
      );
    } on FormatException {
      return null;
    }
  }

  Widget _field({
    required String name,
    required String label,
    required TextEditingController controller,
    required String? error,
    bool decimal = false,
    String? suffix,
  }) => TextField(
    key: ValueKey('estimate-$name'),
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      errorText: error,
      errorMaxLines: 3,
    ),
    onChanged: (_) => setState(() {}),
  );

  Widget _pair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(16) > 22;
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            first,
            const SizedBox(height: Spacing.block),
            second,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: Spacing.stack),
          Expanded(child: second),
        ],
      );
    },
  );

  String get _activityDescription => switch (_activity) {
    'Lightly active' => 'Mostly sitting, with some walking or light exercise.',
    'Moderately active' => 'Regular exercise and movement through the week.',
    'Very active' => 'Hard exercise most days or a physically active job.',
    'Extra active' => 'Heavy physical work alongside demanding training.',
    _ => 'Mostly sitting, with little planned exercise.',
  };

  @override
  Widget build(BuildContext context) {
    final estimate = _estimate;
    final targets = estimate?.targets;
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Suggest for me', style: context.text.screenTitle),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            'Adjust your details to preview your daily targets.',
            style: context.text.caption,
          ),
          const SizedBox(height: Spacing.block),
          _pair(
            _field(
              name: 'age',
              label: 'Age',
              controller: _age,
              error: _ageError,
              suffix: 'years',
            ),
            DropdownButtonFormField<String>(
              key: const Key('estimate-gender'),
              initialValue: _gender,
              isExpanded: true,
              itemHeight: null,
              decoration: const InputDecoration(
                labelText: 'Sex for calculation',
              ),
              items: const [
                DropdownMenuItem(value: 'F', child: Text('Female')),
                DropdownMenuItem(value: 'M', child: Text('Male')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _gender = value);
              },
            ),
          ),
          const SizedBox(height: Spacing.block),
          _pair(
            _field(
              name: 'height',
              label: 'Height',
              controller: _height,
              error: _heightError,
              suffix: 'cm',
              decimal: true,
            ),
            _field(
              name: 'weight',
              label: 'Current weight',
              controller: _weight,
              error: _weightError,
              suffix: widget.useKg ? 'kg' : 'lb',
              decimal: true,
            ),
          ),
          const SizedBox(height: Spacing.block),
          DropdownButtonFormField<String>(
            key: const Key('estimate-activity'),
            initialValue: _activity,
            isExpanded: true,
            itemHeight: null,
            decoration: const InputDecoration(labelText: 'Everyday activity'),
            items: [
              for (final value in TargetCalculator.activityLevels)
                DropdownMenuItem(value: value, child: Text(value)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _activity = value);
            },
          ),
          const SizedBox(height: Spacing.inline),
          Text(_activityDescription, style: context.text.caption),
          const SizedBox(height: Spacing.block),
          Text('Your goal', style: context.text.bodyStrong),
          const SizedBox(height: Spacing.inline),
          Wrap(
            spacing: Spacing.inline,
            runSpacing: Spacing.inline,
            children: [
              for (final goal in TargetCalculator.goals)
                ChoiceChip(
                  key: ValueKey('estimate-goal-$goal'),
                  label: Text(goal),
                  selected: _goal == goal,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  side: BorderSide(color: context.colors.border),
                  onSelected: (_) => setState(() => _goal = goal),
                ),
            ],
          ),
          const SizedBox(height: Spacing.inline),
          Divider(color: context.colors.border),
          const SizedBox(height: Spacing.inline),
          if (estimate != null && targets != null) ...[
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated daily target', style: context.text.caption),
                  Text(
                    '${targets.calories} kcal',
                    key: const Key('estimate-calories'),
                    style: context.text.metric,
                  ),
                  Text(
                    'Maintenance estimate: ${estimate.maintenanceCalories} kcal',
                    key: const Key('estimate-maintenance'),
                    style: context.text.caption,
                  ),
                  const SizedBox(height: Spacing.stack),
                  Wrap(
                    spacing: Spacing.block,
                    runSpacing: Spacing.inline,
                    children: [
                      Text(
                        'Protein ${targets.proteinG} g',
                        style: context.text.bodyStrong,
                      ),
                      Text(
                        'Carbs ${targets.carbsG} g',
                        style: context.text.bodyStrong,
                      ),
                      Text(
                        'Fat ${targets.fatG} g',
                        style: context.text.bodyStrong,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.inline),
            Text(
              'A starting estimate, not a measured requirement. Your meal plan portions stay the same.',
              style: context.text.caption,
            ),
            if (estimate.calorieFloorApplied) ...[
              const SizedBox(height: Spacing.inline),
              Text(
                'Adjusted to the app\'s minimum target. Review this estimate with your coach.',
                style: context.text.caption,
              ),
            ],
            if (estimate.proteinTargetAdjusted) ...[
              const SizedBox(height: Spacing.inline),
              Text(
                'Protein was adjusted to fit the daily energy target.',
                style: context.text.caption,
              ),
            ],
          ] else
            Text(
              'Complete the details above to see your estimate.',
              style: context.text.caption,
            ),
          const SizedBox(height: Spacing.inline),
          PrimaryButton(
            label: 'Use these targets',
            onPressed: estimate == null
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop(estimate);
                  },
          ),
        ],
      ),
    );
  }
}
