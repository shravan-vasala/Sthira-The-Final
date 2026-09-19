import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../models/daily_meal_log.dart';
import '../../../models/food_nutrition.dart';
import '../../../models/packaged_food.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/barcode_food_providers.dart';
import '../../../services/barcode_food_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';
import 'barcode_capture_screen.dart';
import 'packaged_food_editor.dart';

/// Review a product and the amount eaten before appending its nutrition snapshot.
class BarcodeFoodSheet extends ConsumerStatefulWidget {
  const BarcodeFoodSheet({
    super.key,
    required this.slotId,
    required this.slotDisplayName,
    required this.targetDate,
    this.slotEmoji,
    this.autoScan = true,
    this.scannerBuilder,
  });
  final String slotId;
  final String slotDisplayName;
  final String targetDate;
  final String? slotEmoji;
  final bool autoScan;
  final WidgetBuilder? scannerBuilder;

  @override
  ConsumerState<BarcodeFoodSheet> createState() => _BarcodeFoodSheetState();
}

class _BarcodeFoodSheetState extends ConsumerState<BarcodeFoodSheet> {
  final _amount = TextEditingController();
  PackagedFood? _food;
  String? _barcode;
  String? _error;
  bool _lookingUp = false;
  bool _saving = false;
  bool _scanning = false;
  bool _canRetry = false;
  int _request = 0;
  String? _account;

  @override
  void initState() {
    super.initState();
    _account = ref.read(authServiceProvider).uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.autoScan &&
          ref.read(barcodeFoodStoreProvider).recent.isEmpty) {
        _scan();
      }
    });
  }

  @override
  void dispose() {
    _request++;
    _amount.dispose();
    super.dispose();
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  static String _amountText(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
  bool get _ready =>
      _food?.hasCompleteNutrition == true && _food!.name.trim().isNotEmpty;
  double? get _parsedAmount =>
      double.tryParse(_amount.text.trim().replaceAll(',', '.'));
  FoodNutrition? get _nutrition {
    final amount = _parsedAmount;
    if (!_ready || amount == null) return null;
    try {
      return _food!.computeNutrition(amount);
    } on FormatException {
      return null;
    }
  }

  void _select(PackagedFood food, {double? lastAmount}) {
    setState(() {
      _request++;
      _food = food;
      _barcode = food.barcode;
      _lookingUp = false;
      _error = null;
      _amount.text = lastAmount == null ? '' : _amountText(lastAmount);
    });
  }

  Future<void> _scan() async {
    if (_scanning || _saving) return;
    _scanning = true;
    final barcode = await Navigator.of(context, rootNavigator: true)
        .push<String>(
          MaterialPageRoute(
            builder:
                widget.scannerBuilder ?? (_) => const BarcodeCaptureScreen(),
          ),
        );
    _scanning = false;
    if (!mounted || barcode == null) return;
    await _lookup(barcode);
  }

  Future<void> _lookup(String barcode) async {
    final saved = ref.read(barcodeFoodStoreProvider).find(barcode);
    if (saved != null) {
      _select(saved.food, lastAmount: saved.lastAmount);
      return;
    }
    final request = ++_request;
    setState(() {
      _barcode = barcode;
      _food = null;
      _amount.clear();
      _error = null;
      _lookingUp = true;
    });
    try {
      final food = await ref.read(barcodeFoodServiceProvider).lookup(barcode);
      if (!mounted || request != _request) return;
      _select(food);
    } on BarcodeLookupException catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = error.message;
        _canRetry =
            error.kind != BarcodeLookupError.notFound &&
            error.kind != BarcodeLookupError.invalidBarcode;
        _lookingUp = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _error =
            'Could not look up this product. Try again or enter the label.';
        _canRetry = true;
        _lookingUp = false;
      });
    }
  }

  Future<void> _editLabel() async {
    final barcode = _barcode;
    if (barcode == null) return;
    final previousBasis = _food?.basis;
    final food = await showAppBottomSheet<PackagedFood>(
      context: context,
      builder: (_) => PackagedFoodEditor(barcode: barcode, food: _food),
    );
    if (!mounted || food == null) return;
    final lastAmount = food.basis == previousBasis ? _parsedAmount : null;
    _select(food, lastAmount: lastAmount);
  }

  Future<void> _save() async {
    final food = _food;
    final nutrition = _nutrition;
    if (_saving || food == null || nutrition == null) return;
    if (ref.read(authServiceProvider).uid != _account) {
      setState(
        () => _error = 'Your account changed. Close this sheet and try again.',
      );
      return;
    }
    final amount = _parsedAmount!;
    final store = ref.read(barcodeFoodStoreProvider);
    final notifier = ref.read(dailyMealLogProvider.notifier);
    setState(() {
      _saving = true;
      _error = null;
    });
    final item = MealItemLog(
      name: food.name,
      brand: food.brand,
      barcode: food.barcode,
      portion: '${_amountText(amount)} ${food.amountUnit}',
      baseNutrition: food.baseNutrition,
      computedNutrition: nutrition,
      nutritionBasis: food.basis!.name,
      isPer100g: food.basis == NutritionBasis.per100g,
      consumedGrams: food.basis == NutritionBasis.per100g ? amount : null,
      consumedMl: food.basis == NutritionBasis.per100ml ? amount : null,
      consumedServings: food.basis == NutritionBasis.perServing ? amount : null,
      servingGrams: food.servingUnit == FoodQuantityUnit.grams
          ? food.servingQuantity
          : null,
      provenance: food.source == PackagedFoodSource.openFoodFacts
          ? 'barcode'
          : 'label',
      resolved: true,
    );
    try {
      await notifier.appendMealItem(
        widget.slotId,
        item,
        targetDate: widget.targetDate,
        slotName: widget.slotDisplayName,
        slotEmoji: widget.slotEmoji,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not add this food. Your entry is still here; please try again.';
        });
      }
      return;
    }
    // A shortcut-cache failure must never invite a duplicate meal submission.
    var remembered = true;
    try {
      await store.remember(food, amount);
    } catch (_) {
      remembered = false;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          remembered
              ? 'Added to ${widget.slotDisplayName}'
              : 'Food added. Could not save its shortcut on this device.',
        ),
      ),
    );
  }

  List<Widget> _shortcuts(PackagedFood food) {
    final expected = switch (food.basis) {
      NutritionBasis.per100g => FoodQuantityUnit.grams,
      NutritionBasis.per100ml => FoodQuantityUnit.millilitres,
      _ => null,
    };
    final serving = food.basis == NutritionBasis.perServing
        ? 1.0
        : expected != null && food.servingUnit == expected
        ? food.servingQuantity
        : null;
    final package = expected != null && food.packageUnit == expected
        ? food.packageQuantity
        : food.basis == NutritionBasis.perServing &&
              food.packageUnit != null &&
              food.packageUnit == food.servingUnit &&
              food.servingQuantity != null &&
              food.servingQuantity! > 0 &&
              food.packageQuantity != null
        ? food.packageQuantity! / food.servingQuantity!
        : null;
    Widget chip(String label, double value) => ActionChip(
      backgroundColor: context.colors.insetSurface,
      side: BorderSide(color: context.colors.border),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(label, style: context.text.bodyStrong),
      onPressed: _saving
          ? null
          : () => setState(() => _amount.text = _amountText(value)),
    );
    return [
      if (serving != null && serving.isFinite && serving > 0)
        chip('1 serving', serving),
      if (package != null && package.isFinite && package > 0) ...[
        chip('Half pack', package / 2),
        chip('Whole pack', package),
      ],
    ];
  }

  Future<void> _openSource() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.https('world.openfoodfacts.org', '/product/${_food!.barcode}'),
      );
    } catch (_) {
      /* The platform may have no browser handler. */
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Open Food Facts.')),
      );
    }
  }

  Widget _product(PackagedFood food) {
    final nutrition = _nutrition;
    final basis = switch (food.basis) {
      NutritionBasis.per100g => 'Per 100 g',
      NutritionBasis.per100ml => 'Per 100 ml',
      NutritionBasis.perServing => 'Per serving',
      null => 'Check the nutrition basis on the label',
    };
    String nutrient(double? value) =>
        value == null ? 'Unknown' : _number(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          food.name.isEmpty ? 'Unlabelled product' : food.name,
          style: context.text.cardTitle,
        ),
        if (food.brand?.isNotEmpty == true)
          Text(food.brand!, style: context.text.body),
        const SizedBox(height: Spacing.inline),
        Text('Barcode ${food.barcode}', style: context.text.caption),
        if (food.source == PackagedFoodSource.openFoodFacts)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _openSource,
              child: const Text('Source: Open Food Facts'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.inline),
            child: Text('Your package label', style: context.text.caption),
          ),
        Text(basis, style: context.text.bodyStrong),
        const SizedBox(height: Spacing.inline),
        Wrap(
          spacing: Spacing.block,
          runSpacing: Spacing.inline,
          children: [
            Text('${nutrient(food.kcal)} kcal', style: context.text.body),
            Text(
              'Protein ${nutrient(food.proteinG)} g',
              style: context.text.body,
            ),
            Text('Carbs ${nutrient(food.carbsG)} g', style: context.text.body),
            Text('Fat ${nutrient(food.fatG)} g', style: context.text.body),
          ],
        ),
        const SizedBox(height: Spacing.inline),
        Text(
          _ready
              ? 'Check that these values match your pack.'
              : 'Some details are missing. Confirm the basis and nutrients from your label before adding.',
          style: context.text.caption.copyWith(
            color: context.colors.textMedium,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving ? null : _editLabel,
            icon: const Icon(Icons.edit_outlined),
            label: Text(_ready ? 'Edit label values' : 'Complete from label'),
          ),
        ),
        if (_ready) ...[
          const SizedBox(height: Spacing.block),
          TextField(
            key: const Key('packaged-food-amount'),
            controller: _amount,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount eaten (${food.amountUnit})',
              errorText: _amount.text.isNotEmpty && nutrition == null
                  ? 'Enter an amount greater than zero'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Spacing.inline),
          Wrap(
            spacing: Spacing.inline,
            runSpacing: Spacing.inline,
            children: _shortcuts(food),
          ),
          if (nutrition != null) ...[
            const SizedBox(height: Spacing.block),
            Container(
              padding: const EdgeInsets.all(Spacing.block),
              decoration: BoxDecoration(
                color: context.colors.insetSurface,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('For your portion', style: context.text.caption),
                  Text(
                    '${_number(nutrition.kcal)} kcal',
                    style: context.text.cardTitle,
                  ),
                  Wrap(
                    spacing: Spacing.block,
                    runSpacing: Spacing.inline,
                    children: [
                      Text('Protein ${_number(nutrition.proteinG)} g'),
                      Text('Carbs ${_number(nutrition.carbsG)} g'),
                      Text('Fat ${_number(nutrition.fatG)} g'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spacing.block),
          PrimaryButton(
            label: 'Add to ${widget.slotDisplayName}',
            isLoading: _saving,
            onPressed: nutrition == null ? null : _save,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the lookup client alive for the duration of this sheet.
    ref.watch(barcodeFoodServiceProvider);
    final store = ref.watch(barcodeFoodStoreProvider);
    final food = _food;
    return PopScope(
      canPop: !_saving,
      child: AppSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('Packaged food', style: context.text.screenTitle),
                ),
                IconButton(
                  tooltip: 'Close packaged food',
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              '${widget.slotDisplayName} \u00b7 ${DateFormat('EEE, d MMM').format(DateTime.parse(widget.targetDate))}',
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            const SizedBox(height: Spacing.block),
            if (_lookingUp) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: Spacing.block),
              Text(
                'Finding your product\u2026',
                textAlign: TextAlign.center,
                style: context.text.body,
              ),
              TextButton(
                onPressed: () => setState(() {
                  _request++;
                  _lookingUp = false;
                  _barcode = null;
                  _error = null;
                }),
                child: const Text('Cancel lookup'),
              ),
            ] else ...[
              if (_error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: context.text.body),
                ),
                const SizedBox(height: Spacing.block),
                if (food == null && _canRetry && _barcode != null)
                  TextButton(
                    onPressed: () => _lookup(_barcode!),
                    child: const Text('Try lookup again'),
                  ),
              ],
              if (food != null)
                _product(food)
              else if (_barcode != null) ...[
                Text('Barcode $_barcode', style: context.text.caption),
                const SizedBox(height: Spacing.block),
                PrimaryButton(
                  label: 'Enter nutrition from label',
                  icon: Icons.edit_outlined,
                  onPressed: _editLabel,
                ),
              ] else ...[
                Text(
                  'Scan a pack, check its label and choose how much you ate.',
                  style: context.text.body,
                ),
                const SizedBox(height: Spacing.block),
                PrimaryButton(
                  label: 'Scan barcode',
                  icon: Icons.qr_code_scanner,
                  onPressed: _scan,
                ),
                if (store.recent.isNotEmpty) ...[
                  const SizedBox(height: Spacing.block),
                  Text('Recently added', style: context.text.bodyStrong),
                  for (final saved in store.recent.take(8))
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(saved.food.name),
                        subtitle: saved.food.brand == null
                            ? null
                            : Text(saved.food.brand!),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _select(saved.food, lastAmount: saved.lastAmount),
                      ),
                    ),
                ],
              ],
              const SizedBox(height: Spacing.block),
              if (food != null || _barcode != null)
                TextButton.icon(
                  onPressed: _saving ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan another barcode'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
