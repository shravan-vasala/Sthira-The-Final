import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../providers/app_providers.dart';
import '../../../models/daily_meal_log.dart';
import '../../../utils/meal_icons.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class AddMealSlotDialog extends ConsumerStatefulWidget {
  const AddMealSlotDialog({super.key});

  @override
  ConsumerState<AddMealSlotDialog> createState() => _AddMealSlotDialogState();
}

class _AddMealSlotDialogState extends ConsumerState<AddMealSlotDialog> {
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = 'restaurant';
  bool _addToEveryDay = false;
  bool _isSaving = false;
  String? _errorText;

  String? _establishedId;
  late String _capturedTargetDate;
  bool _profileSaveCompleted = false;

  @override
  void initState() {
    super.initState();
    _capturedTargetDate = ref.read(dateStringProvider);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Name cannot be blank');
      return;
    }
    if (name.length > 50) {
      setState(() => _errorText = 'Name is too long');
      return;
    }

    final nameLower = name.toLowerCase();

    // Only check for duplicates if we haven't established an ID yet
    if (_establishedId == null) {
      final profile = ref.read(profileProvider);
      final isProfileDuplicate = profile.customMealSlots.any(
        (slot) => (slot['name'] as String?)?.toLowerCase() == nameLower,
      );

      final dailyLog = ref.read(dailyMealLogProvider);
      final isDailyDuplicate =
          dailyLog.customSlots.values.any(
            (slot) => slot.name?.toLowerCase() == nameLower,
          ) ??
          false;

      if (isProfileDuplicate || isDailyDuplicate) {
        setState(
          () => _errorText = 'A meal slot with this name already exists',
        );
        return;
      }
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    _establishedId ??=
        '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      if (_addToEveryDay && !_profileSaveCompleted) {
        final profile = ref.read(profileProvider);
        final updatedSlots =
            List<Map<String, dynamic>>.from(profile.customMealSlots)..add({
              'id': _establishedId,
              'name': name,
              'emoji': _selectedEmoji,
              'isDefault': true,
            });
        await ref
            .read(profileProvider.notifier)
            .updateProfile(profile.copyWith(customMealSlots: updatedSlots));
        _profileSaveCompleted = true;
      }

      // Create an empty log entry for today so it immediately appears (and persists name/emoji)
      final slotLog = MealSlotLog(
        name: name,
        emoji: _selectedEmoji,
        items: [],
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
      );

      await ref
          .read(dailyMealLogProvider.notifier)
          .saveMealSlot(
            _establishedId!,
            slotLog,
            targetDate: _capturedTargetDate,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = 'Failed to save meal slot.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sheet)),
      title: Text('Add Meal Slot', style: context.text.screenTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Meal Name',
                hintText: 'e.g. Post-workout shake',
                errorText: _errorText,
                filled: true,
                fillColor: context.colors.inputFill,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Choose an icon',
              style: context.text.eyebrow.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealIcons.options.map((opt) {
                final isSelected = opt.id == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = opt.id),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 24),
            Row(
              children: [
                Switch(
                  value: _addToEveryDay,
                  onChanged: (val) => setState(() => _addToEveryDay = val),
                  activeTrackColor: context.colors.primary.withValues(
                    alpha: 0.5,
                  ),
                  activeThumbColor: context.colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add to every day?',
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Text(
                'If enabled, this slot will appear every day. Otherwise, just for ${DateFormat('MMM d').format(DateTime.parse(_capturedTargetDate))}.',
                style: context.text.micro.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: context.text.body.copyWith(color: context.colors.textLight),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.onPrimary,
                  ),
                )
              : const Text('Add Slot'),
        ),
      ],
    );
  }
}
