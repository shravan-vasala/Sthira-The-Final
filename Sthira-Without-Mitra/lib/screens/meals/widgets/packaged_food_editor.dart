import 'dart:async';

import 'package:flutter/material.dart';
import '../../../models/packaged_food.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';

/// Reads the user's package label. Missing values are intentionally blank.
class PackagedFoodEditor extends StatefulWidget {
  const PackagedFoodEditor({super.key, required this.barcode, this.food});
  final String barcode;
  final PackagedFood? food;

  @override
  State<PackagedFoodEditor> createState() => _PackagedFoodEditorState();
}

class _PackagedFoodEditorState extends State<PackagedFoodEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final List<TextEditingController> _nutrients;
  late final TextEditingController _package;
  late final TextEditingController _serving;
  NutritionBasis? _basis;

  @override
  void initState() {
    super.initState();
    final food = widget.food;
    _basis = food?.basis;
    _name = TextEditingController(text: food?.name ?? '');
    _brand = TextEditingController(text: food?.brand ?? '');
    _nutrients = [food?.kcal, food?.proteinG, food?.carbsG, food?.fatG]
        .map(
          (value) =>
              TextEditingController(text: value == null ? '' : _number(value)),
        )
        .toList();
    final expectedUnit = _unit(_basis);
    _package = TextEditingController(
      text: expectedUnit != null && food?.packageUnit == expectedUnit
          ? _number(food?.packageQuantity)
          : '',
    );
    _serving = TextEditingController(
      text: expectedUnit != null && food?.servingUnit == expectedUnit
          ? _number(food?.servingQuantity)
          : '',
    );
  }

  static FoodQuantityUnit? _unit(NutritionBasis? basis) => switch (basis) {
    NutritionBasis.per100g => FoodQuantityUnit.grams,
    NutritionBasis.per100ml => FoodQuantityUnit.millilitres,
    _ => null,
  };
  static String _number(double? value) => value == null
      ? ''
      : value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    for (final controller in [
      _name,
      _brand,
      ..._nutrients,
      _package,
      _serving,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateNutrient(String? value) {
    final parsed = _parse(value ?? '');
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return 'Enter the label value';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = _parse(value);
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return 'Enter an amount above zero';
    }
    return null;
  }

  void _save() {
    final invalidFields = _form.currentState!.validateGranularly();
    if (invalidFields.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final field = invalidFields.first;
        if (mounted && field.mounted) {
          unawaited(Scrollable.ensureVisible(field.context, alignment: 0.1));
        }
      });
      return;
    }
    final unit = _unit(_basis);
    final food = PackagedFood(
      barcode: widget.barcode,
      name: _name.text.trim(),
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      basis: _basis,
      kcal: _parse(_nutrients[0].text),
      proteinG: _parse(_nutrients[1].text),
      carbsG: _parse(_nutrients[2].text),
      fatG: _parse(_nutrients[3].text),
      packageQuantity: unit == null ? null : _parse(_package.text),
      packageUnit: unit,
      servingQuantity: unit == null ? null : _parse(_serving.text),
      servingUnit: unit,
      source: PackagedFoodSource.manual,
    );
    Navigator.of(context).pop(food);
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool numeric = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.block),
    child: TextFormField(
      controller: controller,
      style: context.text.body,
      decoration: InputDecoration(labelText: label),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textCapitalization: numeric
          ? TextCapitalization.none
          : TextCapitalization.words,
      validator: validator,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final unit = _unit(_basis);
    final unitLabel = unit == FoodQuantityUnit.grams ? 'g' : 'ml';
    return AppSheet(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Keep the heading in the same scroll area as the form so large text
            // and the keyboard cannot consume all space available for the fields.
            Text(
              'Nutrition from the label',
              style: context.text.screenTitle.copyWith(
                color: context.colors.textDark,
              ),
            ),
            const SizedBox(height: Spacing.inline),
            Text(
              'Enter values exactly as printed. Use 0 only when the label says zero.',
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            const SizedBox(height: Spacing.screen),
            _field(
              'Product name',
              _name,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a product name' : null,
            ),
            _field('Brand (optional)', _brand),
            DropdownButtonFormField<NutritionBasis>(
              initialValue: _basis,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Values on the label are',
              ),
              items: const [
                DropdownMenuItem(
                  value: NutritionBasis.per100g,
                  child: Text('Per 100 g'),
                ),
                DropdownMenuItem(
                  value: NutritionBasis.per100ml,
                  child: Text('Per 100 ml'),
                ),
                DropdownMenuItem(
                  value: NutritionBasis.perServing,
                  child: Text('Per serving'),
                ),
              ],
              validator: (value) => value == null
                  ? 'Choose the basis printed on the label'
                  : null,
              onChanged: (value) => setState(() {
                if (_basis != value) {
                  _package.clear();
                  _serving.clear();
                }
                _basis = value;
              }),
            ),
            const SizedBox(height: Spacing.block),
            _field(
              'Energy (kcal)',
              _nutrients[0],
              numeric: true,
              validator: _validateNutrient,
            ),
            _field(
              'Protein (g)',
              _nutrients[1],
              numeric: true,
              validator: _validateNutrient,
            ),
            _field(
              'Carbohydrate (g)',
              _nutrients[2],
              numeric: true,
              validator: _validateNutrient,
            ),
            _field(
              'Fat (g)',
              _nutrients[3],
              numeric: true,
              validator: _validateNutrient,
            ),
            if (unit != null) ...[
              _field(
                'Pack size ($unitLabel, optional)',
                _package,
                numeric: true,
                validator: _validateQuantity,
              ),
              _field(
                'Serving size ($unitLabel, optional)',
                _serving,
                numeric: true,
                validator: _validateQuantity,
              ),
            ],
            Text(
              'These values will be saved for this barcode on your device.',
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            const SizedBox(height: Spacing.block),
            PrimaryButton(label: 'Use label values', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
