import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';
import '../../../providers/app_providers.dart';
import '../../../utils/format_units.dart';
import '../../../models/user_profile.dart';
import '../../../models/habit.dart';
import '../photo_viewer_screen.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class AddProgressPhotoSheet extends ConsumerStatefulWidget {
  const AddProgressPhotoSheet({super.key});

  @override
  ConsumerState<AddProgressPhotoSheet> createState() =>
      _AddProgressPhotoSheetState();
}

class _AddProgressPhotoSheetState extends ConsumerState<AddProgressPhotoSheet> {
  final _picker = ImagePicker();
  String? _selectedPose;
  late TextEditingController _weightController;
  late TextEditingController _noteController;
  XFile? _pickedImage;
  bool _isSaving = false;
  bool _isPicking = false;
  String? _weightError;
  late final DateTime _date;
  late final int _accountGeneration;
  late final UserProfile _profile;
  bool get _sameAccount =>
      mounted &&
      ref.read(accountGenerationProvider) == _accountGeneration &&
      !ref.read(accountTransitionProvider);

  @override
  void initState() {
    super.initState();
    _date = ref.read(selectedDateProvider);
    _accountGeneration = ref.read(accountGenerationProvider);
    _profile = ref.read(profileProvider);
    _weightController = TextEditingController();
    _noteController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_sameAccount) return;
      final selectedDate = _date;
      final date = DateFormat('yyyy-MM-dd').format(selectedDate);
      final currentWeight = ref.read(dailyLogRepoProvider).getLog(date)?.weight;
      if (currentWeight != null && currentWeight > 0) {
        final displayWeight = convertFromKg(_profile, currentWeight);
        _weightController.text = displayWeight.toStringAsFixed(1);
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedPose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pose first.')),
      );
      return;
    }
    if (_isPicking || _isSaving || !_sameAccount) return;
    setState(() => _isPicking = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null && _sameAccount) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (_) {
      if (mounted && _sameAccount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the camera or gallery. Try again; your entries are kept.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _savePhoto() async {
    if (_pickedImage == null ||
        _selectedPose == null ||
        _isSaving ||
        !_sameAccount)
      return;
    final text = _weightController.text.trim();
    final enteredWeight = double.tryParse(text);
    if (text.isNotEmpty &&
        (enteredWeight == null ||
            !enteredWeight.isFinite ||
            enteredWeight <= 0)) {
      setState(
        () => _weightError = 'Enter a positive weight or leave it blank.',
      );
      return;
    }
    final weight = enteredWeight == null
        ? null
        : convertToKg(_profile, enteredWeight);
    setState(() {
      _isSaving = true;
      _weightError = null;
    });
    final date = DateFormat('yyyy-MM-dd').format(_date);
    final mediaRepo = ref.read(mediaRepoProvider);
    final selectedPose = _selectedPose!;
    final image = _pickedImage!;
    final note = _noteController.text;
    try {
      final imageBytes = await image.readAsBytes();
      if (!_sameAccount) throw StateError('Account changed');
      await mediaRepo.saveProgressPhoto(
        date,
        imageBytes,
        poseTag: selectedPose,
        weight: weight,
        note: note,
      );

      // The photo is committed. Optional habit feedback must not invite a duplicate save.
      if (_sameAccount) {
        final photoHabit = ref
            .read(allHabitsProvider)
            .where(
              (h) =>
                  isHabitScheduledOn(h, _date) &&
                  (h.name.toLowerCase().contains('photo') ||
                      h.name.toLowerCase().contains('picture')),
            )
            .firstOrNull;
        if (photoHabit != null) {
          try {
            await ref
                .read(habitCompletionsProvider.notifier)
                .setOverrideForDate(date, photoHabit.id, 'done');
          } catch (_) {
            if (mounted && _sameAccount) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Photo saved. The photo habit could not be updated.',
                  ),
                ),
              );
            }
          }
        }
      }
      if (mounted) {
        Navigator.pop(context, true); // true indicates successful save
      }
    } catch (e) {
      if (mounted && _sameAccount) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save your photo. Your entries are kept; please try again.',
            ),
          ),
        );
      }
    }
  }

  void _openReferenceViewer(String photoPath, String date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          photos: [
            PhotoItem(path: photoPath, date: date, poseTag: _selectedPose!),
          ],
          initialIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(accountGenerationProvider) != _accountGeneration) {
      return const AppSheet(
        title: 'Account changed',
        child: Text('Reopen Add progress photo for this account.'),
      );
    }
    PhotoItem? referencePhoto;
    if (_selectedPose != null) {
      // Find the most recent photo for this pose
      final allPhotos = ref
          .read(mediaRepoProvider)
          .getAllProgressPhotosDetailed();
      final previousPosePhotos = allPhotos
          .where((p) => p.pose == _selectedPose)
          .toList();
      if (previousPosePhotos.isNotEmpty) {
        final recent = previousPosePhotos.first;
        referencePhoto = PhotoItem(
          path: recent.path,
          date: recent.date,
          poseTag: recent.pose,
        );
      }
    }

    final selectedDate = _date;
    final sameAccount =
        ref.watch(accountGenerationProvider) == _accountGeneration;

    return AppSheet(
      title: 'Add Progress Photo',
      subtitle: 'For ${DateFormat('MMM d, yyyy').format(selectedDate)}',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('POSE (REQUIRED)', style: context.text.eyebrow),
          const SizedBox(height: Spacing.inline),
          Row(
            children: [
              Expanded(
                child: _PoseSelectorOption(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Front',
                  isSelected: _selectedPose == 'front',
                  onTap: () => setState(() => _selectedPose = 'front'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PoseSelectorOption(
                  icon: Icons.sync_alt_rounded,
                  label: 'Side',
                  isSelected: _selectedPose == 'side',
                  onTap: () => setState(() => _selectedPose = 'side'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PoseSelectorOption(
                  icon: Icons.turn_left_rounded,
                  label: 'Back',
                  isSelected: _selectedPose == 'back',
                  onTap: () => setState(() => _selectedPose = 'back'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_pickedImage == null) ...[
            Text('SOURCE', style: context.text.eyebrow),
            const SizedBox(height: Spacing.inline),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                if (referencePhoto != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openReferenceViewer(
                        referencePhoto!.path,
                        referencePhoto.date,
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.colors.primary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(
                                      referencePhoto.path,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          semanticLabel:
                                              'Reference photo unavailable',
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(
                                        ref
                                            .read(mediaRepoProvider)
                                            .getAbsolutePath(
                                              referencePhoto.path,
                                            ),
                                      ),
                                      fit: BoxFit.cover,
                                      cacheWidth: 200,
                                      errorBuilder: (_, _, _) => const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          semanticLabel: 'Photo unavailable',
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Match Angle',
                            style: context.text.micro.copyWith(
                              color: context.colors.primary,
                            ),
                          ),
                          Text(
                            _formatDate(referencePhoto.date),
                            style: context.text.micro.copyWith(
                              color: context.colors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            // Confirm Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.insetSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            _pickedImage!.path,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_pickedImage!.path),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            cacheWidth: 200,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                semanticLabel: 'Photo unavailable',
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Looks good?',
                          style: context.text.body.copyWith(
                            color: context.colors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _pickedImage = null),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            minimumSize: const Size(44, 44),
                          ),
                          child: Text(
                            'Retake',
                            style: context.text.caption.copyWith(
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          TextField(
            controller: _weightController,
            enabled: !_isSaving && sameAccount,
            onChanged: (_) => setState(() => _weightError = null),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.numeric(
              context.text.body.copyWith(color: context.colors.textDark),
            ),
            decoration: InputDecoration(
              labelText: 'Weight (${_profile.weightUnit}, optional)',
              errorText: _weightError,
              prefixIcon: Icon(
                Icons.monitor_weight_outlined,
                color: context.colors.textLight,
              ),
              fillColor: context.colors.inputFill,
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            enabled: !_isSaving && sameAccount,
            style: context.text.body.copyWith(color: context.colors.textDark),
            decoration: InputDecoration(
              labelText: 'Note (Optional)',
              prefixIcon: Icon(
                Icons.notes_rounded,
                color: context.colors.textLight,
              ),
              hintText: 'e.g. Post-workout pump',
              fillColor: context.colors.inputFill,
              filled: true,
            ),
          ),

          const SizedBox(height: Spacing.section),
          PrimaryButton(
            onPressed:
                (_pickedImage != null &&
                    !_isSaving &&
                    sameAccount &&
                    !_isPicking)
                ? _savePhoto
                : null,
            label: 'Save Progress Photo',
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

class _PoseSelectorOption extends StatelessWidget {
  const _PoseSelectorOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: AnimatedContainer(
          duration: Motion.standard,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.primary : context.colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? context.colors.onPrimary
                    : context.colors.primary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: context.text.micro.copyWith(
                  color: isSelected
                      ? context.colors.onPrimary
                      : context.colors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.card),
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(Spacing.inline),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.colors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.text.micro.copyWith(color: context.colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
