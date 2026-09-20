import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/daily_meal_log.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/meal_serving.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';

enum AddServingResult { added, photo, describe }

/// Quick extra portions under the meal's existing Add Serving action.
class AddServingSheet extends ConsumerStatefulWidget {
  const AddServingSheet({
    super.key,
    required this.slotId,
    required this.slotDisplayName,
    required this.targetDate,
    required this.slotLog,
    this.slotEmoji,
  });

  final String slotId;
  final String slotDisplayName;
  final String targetDate;
  final MealSlotLog slotLog;
  final String? slotEmoji;

  @override
  ConsumerState<AddServingSheet> createState() => _AddServingSheetState();
}

class _AddServingSheetState extends ConsumerState<AddServingSheet> {
  final _customAmount = TextEditingController();
  late final int _account;
  late final List<MealItemLog> _foods;
  int _selected = 0;
  double _multiplier = 1;
  bool _custom = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _account = ref.read(accountGenerationProvider);
    final unique = <String, MealItemLog>{};
    for (final item in widget.slotLog.items) {
      if (!MealServing.canRepeat(widget.slotLog, item)) continue;
      final snapshot = item.copy()
        ..macrosKnown = widget.slotLog.hasKnownMacrosFor(item);
      unique.putIfAbsent(
        jsonEncode(
          snapshot.toJson().map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        ),
        () => snapshot,
      );
    }
    _foods = unique.values.toList();
  }

  @override
  void dispose() {
    _customAmount.dispose();
    super.dispose();
  }

  MealItemLog? get _extra {
    if (_foods.isEmpty) return null;
    final amount = _custom
        ? double.tryParse(_customAmount.text.trim().replaceAll(',', '.'))
        : _multiplier;
    if (amount == null) return null;
    try {
      return MealServing.repeat(widget.slotLog, _foods[_selected], amount);
    } on FormatException {
      return null;
    }
  }

  bool get _accountReady =>
      ref.read(accountGenerationProvider) == _account &&
      !ref.read(accountTransitionProvider) &&
      !ref.read(accountHydratingProvider);

  Future<void> _save() async {
    final extra = _extra;
    if (_saving || !_accountReady || extra == null) return;
    final notifier = ref.read(dailyMealLogProvider.notifier);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await notifier.appendMealItem(
        widget.slotId,
        extra,
        targetDate: widget.targetDate,
        slotName: widget.slotDisplayName,
        slotEmoji: widget.slotEmoji,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not add this serving. Your selection is still here; try again.';
        });
      }
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final sameAccount = _accountReady;
    Navigator.of(context).pop(AddServingResult.added);
    if (sameAccount) {
      messenger.showSnackBar(
        SnackBar(content: Text('Added to ${widget.slotDisplayName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountChanged = ref.watch(accountGenerationProvider) != _account;
    final unavailable =
        accountChanged ||
        ref.watch(accountTransitionProvider) ||
        ref.watch(accountHydratingProvider);
    final extra = _extra;
    final original = _foods.isEmpty ? null : _foods[_selected];
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
                  child: Text('Add Serving', style: context.text.screenTitle),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              '${widget.slotDisplayName} \u00b7 ${DateFormat('EEE, d MMM').format(DateTime.parse(widget.targetDate))}',
              style: context.text.caption,
            ),
            const SizedBox(height: Spacing.block),
            if (unavailable)
              Text(
                'Your account is changing. Close this sheet and reopen the meal.',
                style: context.text.body,
              )
            else ...[
              if (original != null) ...[
                ...[
                  Text('Same food again', style: context.text.cardTitle),
                  const SizedBox(height: Spacing.inline),
                  if (_foods.length == 1)
                    Text(
                      original.name ?? 'Food',
                      style: context.text.bodyStrong,
                    )
                  else
                    Material(
                      color: Colors.transparent,
                      child: RadioGroup<int>(
                        groupValue: _selected,
                        onChanged: (value) {
                          if (!_saving && value != null) {
                            setState(() {
                              _selected = value;
                              _error = null;
                            });
                          }
                        },
                        child: Column(
                          children: [
                            for (var index = 0; index < _foods.length; index++)
                              RadioListTile<int>(
                                contentPadding: EdgeInsets.zero,
                                value: index,
                                enabled: !_saving,
                                title: Text(_foods[index].name ?? 'Food'),
                                subtitle: Text(
                                  _foods[index].portion ?? 'Logged portion',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: Spacing.inline),
                  Text(
                    '1\u00d7 = another ${original.portion?.trim().isNotEmpty == true ? original.portion : 'logged portion'}',
                    style: context.text.caption,
                  ),
                  const SizedBox(height: Spacing.block),
                  Text('Extra amount', style: context.text.bodyStrong),
                  const SizedBox(height: Spacing.inline),
                  Wrap(
                    spacing: Spacing.inline,
                    runSpacing: Spacing.inline,
                    children: [
                      for (final amount in [0.5, 1.0, 1.5, 2.0])
                        ChoiceChip(
                          label: Text('${MealServing.number(amount)}\u00d7'),
                          selected: !_custom && amount == _multiplier,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          backgroundColor: context.colors.insetSurface,
                          side: BorderSide(color: context.colors.border),
                          onSelected: _saving
                              ? null
                              : (_) => setState(() {
                                  _multiplier = amount;
                                  _custom = false;
                                  _error = null;
                                }),
                        ),
                      ChoiceChip(
                        label: const Text('Custom'),
                        selected: _custom,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: context.colors.insetSurface,
                        side: BorderSide(color: context.colors.border),
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _custom = true),
                      ),
                    ],
                  ),
                  if (_custom) ...[
                    const SizedBox(height: Spacing.inline),
                    TextField(
                      key: const Key('extra-serving-amount'),
                      controller: _customAmount,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Times the logged portion',
                        hintText: 'For example, 0.5',
                        errorText:
                            _customAmount.text.isNotEmpty && extra == null
                            ? 'Enter a valid amount greater than zero'
                            : null,
                      ),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ],
                  const SizedBox(height: Spacing.block),
                  if (extra != null) ...[
                    Text(
                      '+${extra.computedNutrition!.kcal.round()} kcal',
                      style: context.text.cardTitle,
                    ),
                    Text(extra.portion!, style: context.text.body),
                    const SizedBox(height: Spacing.inline),
                    if (extra.hasKnownMacros)
                      Wrap(
                        spacing: Spacing.inline,
                        runSpacing: Spacing.inline,
                        children: [
                          Text(
                            'Protein ${NumberFormat('0.#').format(extra.computedNutrition!.proteinG)} g',
                            style: context.text.caption,
                          ),
                          Text(
                            'Carbs ${NumberFormat('0.#').format(extra.computedNutrition!.carbsG)} g',
                            style: context.text.caption,
                          ),
                          Text(
                            'Fat ${NumberFormat('0.#').format(extra.computedNutrition!.fatG)} g',
                            style: context.text.caption,
                          ),
                        ],
                      )
                    else
                      Text(
                        'Macros not available for this food',
                        style: context.text.caption,
                      ),
                    const SizedBox(height: Spacing.block),
                  ],
                  if (_error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(_error!, style: context.text.body),
                    ),
                    const SizedBox(height: Spacing.inline),
                  ],
                  PrimaryButton(
                    label: 'Add to ${widget.slotDisplayName}',
                    onPressed: extra == null ? null : _save,
                    isLoading: _saving,
                  ),
                ],
                const SizedBox(height: Spacing.block),
              ],
              ...[
                Text('Something different?', style: context.text.bodyStrong),
                const SizedBox(height: Spacing.inline),
                Wrap(
                  spacing: Spacing.inline,
                  runSpacing: Spacing.inline,
                  children: [
                    TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(AddServingResult.photo),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                    ),
                    TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(AddServingResult.describe),
                      icon: const Icon(Icons.notes_rounded),
                      label: const Text('Describe'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
