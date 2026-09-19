import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../models/body_stats.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/layout_insets.dart';

class BodyStatsScreen extends ConsumerStatefulWidget {
  const BodyStatsScreen({super.key});

  @override
  ConsumerState<BodyStatsScreen> createState() => _BodyStatsScreenState();
}

class _BodyStatsScreenState extends ConsumerState<BodyStatsScreen> {
  final _controllers = <String, TextEditingController>{};
  bool _isEditing = false;
  bool _isSaving = false;
  final _errors = <String, String>{};
  String _unit = 'cm';
  late final int _accountGeneration;

  final _fields = [
    'Waist',
    'Hips',
    'Chest',
    'Left Arm',
    'Right Arm',
    'Left Thigh',
    'Right Thigh',
    'Neck',
  ];

  bool _isPrefilled = false;
  String? _prefillDate;
  late final String _pinnedDateStr;

  @override
  void initState() {
    super.initState();
    _pinnedDateStr = ref.read(dateStringProvider);
    _accountGeneration = ref.read(accountGenerationProvider);
    for (final f in _fields) {
      _controllers[f] = TextEditingController();
    }
    _loadData();
  }

  void _loadData() {
    final stats = ref.read(bodyStatsRepoProvider).getStats(_pinnedDateStr);
    if (stats != null) {
      _isPrefilled = false;
      _prefillDate = null;
      _fillControllers(stats);
      return;
    }

    final latest = ref.read(bodyStatsRepoProvider).getLatestStats();
    if (latest != null) {
      _isPrefilled = true;
      _prefillDate = latest.date;
      _fillControllers(latest);
    } else {
      _isPrefilled = false;
      _prefillDate = null;
      for (final f in _fields) {
        _controllers[f]!.clear();
      }
    }
  }

  void _fillControllers(BodyStats stats) {
    _unit = stats.unit;
    final m = stats.allMeasurements;
    for (final f in _fields) {
      if (m[f] != null) {
        _controllers[f]!.text = m[f]!.toStringAsFixed(1);
      } else {
        _controllers[f]!.clear();
      }
    }
  }

  bool _hasMutatedFields(BodyStats? original) {
    if (original == null) return true;
    final m = original.allMeasurements;
    for (final f in _fields) {
      final prefillVal = (m[f] != null) ? m[f]!.toStringAsFixed(1) : '';
      final currentVal = _controllers[f]!.text.trim();
      // If any field has been changed by the user, return true.
      if (prefillVal != currentVal && (prefillVal != '' || currentVal != '')) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(accountGenerationProvider) != _accountGeneration) {
      return Scaffold(
        appBar: AppBar(title: const Text('Body stats')),
        body: const Center(child: Text('Account changed. Reopen body stats.')),
      );
    }
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Body Stats'),
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Cancel editing',
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _errors.clear();
                          _isEditing = false;
                          _loadData();
                        });
                      },
              )
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
        actions: [
          TextButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (_isEditing) {
                      await _save();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
            child: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.accentText,
                    ),
                  )
                : Text(
                    _isEditing ? 'Save' : 'Edit',
                    style: context.text.body.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Spacing.screen,
          Spacing.screen,
          Spacing.screen,
          shellScrollBottomPadding(context),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.section),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALL MEASUREMENTS FOR ${DateFormat('MMM d, yyyy').format(DateTime.parse(_pinnedDateStr)).toUpperCase()}',
                  style: context.text.eyebrow,
                ),
                if (_isPrefilled && _prefillDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Prefilled from ${DateFormat('MMM d').format(DateTime.parse(_prefillDate!))} measurement',
                      style: context.text.micro.copyWith(
                        color: context.colors.textMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final useSingleColumn =
                  width < 340 ||
                  MediaQuery.textScalerOf(context).scale(15) > 20;
              final itemWidth = useSingleColumn
                  ? width
                  : (width - Spacing.stack) / 2;
              return Wrap(
                spacing: Spacing.stack,
                runSpacing: Spacing.stack,
                children: _fields
                    .map(
                      (f) => SizedBox(width: itemWidth, child: _buildField(f)),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField(String field) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            field,
            style: context.text.caption.copyWith(
              color: context.colors.textMedium,
            ),
          ),
          const SizedBox(height: Spacing.inline),
          _isEditing
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: ValueKey('body-stat-$field'),
                        controller: _controllers[field],
                        enabled: !_isSaving,
                        onChanged: (_) {
                          if (_errors.containsKey(field)) {
                            setState(() => _errors.remove(field));
                          }
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: context.text.screenTitle.copyWith(
                          color: context.colors.primary,
                        ),
                        decoration: InputDecoration(
                          errorText: _errors[field],
                          errorMaxLines: 3,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        _unit == 'inches' ? 'in' : 'cm',
                        style: context.text.micro.copyWith(
                          color: context.colors.textMedium,
                        ),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: Spacing.textPair,
                  children: [
                    Text(
                      _controllers[field]!.text.isEmpty
                          ? '--'
                          : _controllers[field]!.text,
                      style: context.text.screenTitle.copyWith(
                        color: _controllers[field]!.text.isEmpty
                            ? context.colors.textLight
                            : context.colors.textDark,
                      ),
                    ),
                    if (_controllers[field]!.text.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          _unit == 'inches' ? 'in' : 'cm',
                          style: context.text.micro.copyWith(
                            color: context.colors.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving ||
        ref.read(accountGenerationProvider) != _accountGeneration ||
        ref.read(accountTransitionProvider))
      return;
    final errors = <String, String>{};
    for (final field in _fields) {
      final text = _controllers[field]!.text.trim();
      final value = double.tryParse(text);
      if (text.isNotEmpty && (value == null || !value.isFinite || value <= 0)) {
        errors[field] = 'Enter a positive measurement.';
      }
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;
    setState(() => _isSaving = true);
    try {
      final date = _pinnedDateStr;

      // Prevent silent duplication of prefill logic
      if (_isPrefilled && _prefillDate != date) {
        final latest = ref.read(bodyStatsRepoProvider).getLatestStats();
        if (!_hasMutatedFields(latest)) {
          // Nothing was mutated, cancel save
          if (mounted) {
            setState(() {
              _isEditing = false;
              _isSaving = false;
            });
          }
          return;
        }
      }

      final stats = BodyStats(
        date: date,
        unit: _unit,
        waist: double.tryParse(_controllers['Waist']!.text),
        hips: double.tryParse(_controllers['Hips']!.text),
        chest: double.tryParse(_controllers['Chest']!.text),
        leftArm: double.tryParse(_controllers['Left Arm']!.text),
        rightArm: double.tryParse(_controllers['Right Arm']!.text),
        leftThigh: double.tryParse(_controllers['Left Thigh']!.text),
        rightThigh: double.tryParse(_controllers['Right Thigh']!.text),
        neck: double.tryParse(_controllers['Neck']!.text),
      );
      await ref.read(bodyStatsRepoProvider).saveStats(stats);
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _isPrefilled = false;
          _prefillDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save body stats.')),
        );
      }
    }
  }
}
