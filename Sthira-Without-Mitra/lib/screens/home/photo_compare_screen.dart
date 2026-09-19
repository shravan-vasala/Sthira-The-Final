import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/app_motion.dart';

import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_bottom_sheet.dart';
import 'photo_viewer_screen.dart'; // To reuse PhotoItem
import '../../share/share_card_exporter.dart';
import '../../services/haptics.dart';
import '../../utils/format_units.dart';
import '../../theme/app_theme.dart';
import 'widgets/add_progress_photo_sheet.dart';

enum CompareMode { sideBySide, slider }

class PhotoCompareScreen extends ConsumerStatefulWidget {
  const PhotoCompareScreen({super.key});

  @override
  ConsumerState<PhotoCompareScreen> createState() => _PhotoCompareScreenState();
}

class _PhotoCompareScreenState extends ConsumerState<PhotoCompareScreen> {
  final GlobalKey _shareKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();

  PhotoItem? _leftPhoto;
  PhotoItem? _rightPhoto;
  List<PhotoItem> _allPhotos = [];
  CompareMode _mode = CompareMode.sideBySide;
  double _sliderPosition = 0.5;
  bool _isSharing = false;
  late final int _accountGeneration;
  bool get _ownsPhotos =>
      mounted &&
      ref.read(accountGenerationProvider) == _accountGeneration &&
      !ref.read(accountTransitionProvider);

  // For bottom picker filtering
  String _pickerFilter = 'all';

  @override
  void initState() {
    super.initState();
    _accountGeneration = ref.read(accountGenerationProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ownsPhotos) _initPhotos();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _loadPhotos() {
    final mediaRepo = ref.read(mediaRepoProvider);
    final allEntries = mediaRepo.getAllProgressPhotos();

    _allPhotos = [];
    for (final entry in allEntries) {
      final date = entry.key;
      for (final path in entry.value) {
        final poseTag = mediaRepo.getPoseTag(path);
        _allPhotos.add(PhotoItem(path: path, date: date, poseTag: poseTag));
      }
    }
  }

  void _initPhotos() {
    _loadPhotos();

    if (_allPhotos.isEmpty) return;

    PhotoItem rightPhoto = _allPhotos.first;
    PhotoItem? leftPhoto;

    final poses = _allPhotos
        .map((p) => p.poseTag)
        .where((p) => p != 'none')
        .toSet();
    if (poses.isNotEmpty) {
      for (final pose in poses) {
        final posePhotos = _allPhotos.where((p) => p.poseTag == pose).toList();
        if (posePhotos.length > 1) {
          final newestPose = posePhotos.first;
          final olderPose = posePhotos
              .skip(1)
              .where((p) => p.date != newestPose.date)
              .firstOrNull;
          if (olderPose != null) {
            rightPhoto = newestPose;
            leftPhoto = olderPose;
            break;
          }
        }
      }
    }

    leftPhoto ??= _allPhotos
        .where((p) => p.date != rightPhoto.date)
        .firstOrNull;
    leftPhoto ??= _allPhotos.length > 1 ? _allPhotos.last : null;

    setState(() {
      _leftPhoto = leftPhoto;
      _rightPhoto = rightPhoto;
    });
  }

  void _swapPhotos() {
    if (!_ownsPhotos) return;
    Haptics.tap();
    setState(() {
      final temp = _leftPhoto;
      _leftPhoto = _rightPhoto;
      _rightPhoto = temp;
    });
  }

  String _formatDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _getTimeDeltaText() {
    if (_leftPhoto == null || _rightPhoto == null) return '';
    try {
      final d1 = DateTime.parse(_leftPhoto!.date);
      final d2 = DateTime.parse(_rightPhoto!.date);
      final diff = d2.difference(d1).inDays.abs();

      String timePart;
      if (diff == 0) {
        timePart = 'Same day';
      } else if (diff < 30)
        timePart = '$diff days apart';
      else {
        final months = (diff / 30).round();
        if (months == 1) {
          timePart = '1 month apart';
        } else if (months < 12)
          timePart = '$months months apart';
        else {
          final years = (months / 12).toStringAsFixed(1);
          timePart = '$years years apart';
        }
      }
      return timePart;
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic> _getWeightDelta() {
    if (_leftPhoto == null || _rightPhoto == null) return {'text': ''};

    final metaL = ref
        .read(mediaRepoProvider)
        .getProgressPhotoMeta(_leftPhoto!.date, _leftPhoto!.path);
    final logL = ref.read(dailyLogRepoProvider).getLog(_leftPhoto!.date);
    double? wL = metaL.weight;
    bool isLMeta = true;
    if (wL == null || wL == 0.0) {
      wL = logL?.weight;
      isLMeta = false;
    }

    final metaR = ref
        .read(mediaRepoProvider)
        .getProgressPhotoMeta(_rightPhoto!.date, _rightPhoto!.path);
    final logR = ref.read(dailyLogRepoProvider).getLog(_rightPhoto!.date);
    double? wR = metaR.weight;
    bool isRMeta = true;
    if (wR == null || wR == 0.0) {
      wR = logR?.weight;
      isRMeta = false;
    }

    if (wL == null || wR == null || wL == 0.0 || wR == 0.0) {
      return {'text': ''};
    }

    final profile = ref.read(profileProvider);
    final dispL = convertFromKg(profile, wL);
    final dispR = convertFromKg(profile, wR);
    final diff = dispR - dispL;

    final sign = diff > 0 ? '+' : '';
    final unit = profile.weightUnit;

    String text = ' · $sign${diff.toStringAsFixed(1)} $unit';
    if (!isLMeta || !isRMeta) {
      text += ' (Est)';
    }

    // logic: green towards target / orange otherwise
    final target = profile.targetWeight;
    Color color = context.colors.textDark; // fallback if no target
    if (target != null && target > 0) {
      final targetDisp = convertFromKg(profile, target);
      final oldDist = (dispL - targetDisp).abs();
      final newDist = (dispR - targetDisp).abs();
      color = newDist < oldDist ? context.colors.green : context.colors.orange;
    }

    return {'text': text, 'color': color};
  }

  void _pickPhoto(bool isLeft) {
    if (!_ownsPhotos) return;
    setState(() => _pickerFilter = 'all');
    _loadPhotos();

    // Check if current selections are still valid
    if (_leftPhoto != null &&
        !_allPhotos.any((p) => p.path == _leftPhoto!.path)) {
      setState(() => _leftPhoto = null);
    }
    if (_rightPhoto != null &&
        !_allPhotos.any((p) => p.path == _rightPhoto!.path)) {
      setState(() => _rightPhoto = null);
    }

    Haptics.tap();
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final generation = ref.watch(accountGenerationProvider);
          final changingAccount = ref.watch(accountTransitionProvider);
          if (generation != _accountGeneration || changingAccount) {
            return const AppSheet(
              title: 'Account changed',
              child: Text('Reopen your photos for this account.'),
            );
          }
          return StatefulBuilder(
            builder: (ctx, setStateSheet) {
              final filtered = _pickerFilter == 'all'
                  ? _allPhotos
                  : _allPhotos
                        .where((p) => p.poseTag == _pickerFilter)
                        .toList();

              return DraggableScrollableSheet(
                initialChildSize: 0.7,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                expand: false,
                builder: (ctx, scrollController) => AppSheet(
                  title: 'Select Photo',
                  draggable: true,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildPickerChip('all', 'All', setStateSheet),
                                const SizedBox(width: 8),
                                _buildPickerChip(
                                  'front',
                                  'Front',
                                  setStateSheet,
                                ),
                                const SizedBox(width: 8),
                                _buildPickerChip('side', 'Side', setStateSheet),
                                const SizedBox(width: 8),
                                _buildPickerChip('back', 'Back', setStateSheet),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Spacing.screen,
                          vertical: Spacing.stack,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          delegate: SliverChildBuilderDelegate((ctx, i) {
                            final item = filtered[i];
                            final isOtherSelected =
                                (!isLeft
                                    ? _leftPhoto?.path
                                    : _rightPhoto?.path) ==
                                item.path;
                            final isCurrentSelected =
                                (isLeft
                                    ? _leftPhoto?.path
                                    : _rightPhoto?.path) ==
                                item.path;

                            return Semantics(
                              button: true,
                              label:
                                  'Select photo from ${_formatDateShort(item.date)}',
                              child: GestureDetector(
                                onTap: () {
                                  if (!_ownsPhotos) return;
                                  if (isOtherSelected) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Photo already selected for the other side.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Haptics.tap();
                                  setState(() {
                                    if (isLeft) {
                                      _leftPhoto = item;
                                    } else {
                                      _rightPhoto = item;
                                    }
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          Radii.chip,
                                        ),
                                        child: kIsWeb
                                            ? Image.network(
                                                item.path,
                                                fit: BoxFit.cover,
                                                cacheWidth: 400,
                                                errorBuilder: (_, _, _) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                              )
                                            : Image.file(
                                                File(
                                                  ref
                                                      .read(mediaRepoProvider)
                                                      .getAbsolutePath(
                                                        item.path,
                                                      ),
                                                ),
                                                fit: BoxFit.cover,
                                                cacheWidth: 400,
                                                errorBuilder: (_, _, _) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                              ),
                                      ),
                                    ),
                                    if (isCurrentSelected)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: context.colors.primary
                                                .withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(
                                              Radii.chip,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.check_circle_rounded,
                                              color: context.colors.onPrimary,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (item.poseTag != 'none')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 2,
                                                  ),
                                              margin: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.6,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      Radii.micro,
                                                    ),
                                              ),
                                              child: Text(
                                                item.poseTag,
                                                style: context.text.micro
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _formatDateShort(item.date),
                                              style: AppTheme.numeric(
                                                context.text.micro.copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }, childCount: filtered.length),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPickerChip(String tag, String label, StateSetter setStateSheet) {
    final isSelected = _pickerFilter == tag;
    return Semantics(
      button: true,
      label: 'Filter by $label',
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          Haptics.tap();
          setStateSheet(() => _pickerFilter = tag);
        },
        child: AnimatedContainer(
          duration: Motion.standard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primary
                : context.colors.inputFill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: context.text.caption.copyWith(
              color: isSelected
                  ? context.colors.onPrimary
                  : context.colors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareCompare() async {
    if (_isSharing || !_ownsPhotos) return;
    Haptics.tap();
    if (_leftPhoto == null || _rightPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select two photos to share.')),
      );
      return;
    }

    final mediaRepo = ref.read(mediaRepoProvider);
    final leftExists =
        kIsWeb ||
        File(mediaRepo.getAbsolutePath(_leftPhoto!.path)).existsSync();
    final rightExists =
        kIsWeb ||
        File(mediaRepo.getAbsolutePath(_rightPhoto!.path)).existsSync();

    if (!leftExists || !rightExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot share missing photos.')),
      );
      return;
    }

    setState(() => _isSharing = true);
    final result = await ShareCardExporter.shareBoundary(
      boundaryKey: _shareKey,
      fileName: 'sthira_compare',
      isCurrent: () => _ownsPhotos,
      text: 'My progress on Sthira! 💪',
    );
    if (!mounted || !_ownsPhotos) return;
    setState(() => _isSharing = false);
    if (result == ShareExportResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share the comparison. Try again.'),
        ),
      );
    }
  }

  Widget _buildPhotoSource(
    PhotoItem? item,
    bool isLeft, {
    BoxFit fit = BoxFit.contain,
  }) {
    if (item == null) {
      return Container(color: Colors.black);
    }

    final mediaRepo = ref.read(mediaRepoProvider);
    final exists =
        kIsWeb || File(mediaRepo.getAbsolutePath(item.path)).existsSync();

    if (!exists) {
      return Container(
        color: context.colors.card,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_rounded,
                color: context.colors.textLight.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Photo Missing',
                textAlign: TextAlign.center,
                style: context.text.body.copyWith(
                  color: context.colors.textLight,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: Spacing.inline,
                runSpacing: Spacing.textPair,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (isLeft) {
                          _leftPhoto = null;
                        } else {
                          _rightPhoto = null;
                        }
                      });
                    },
                    child: Text(
                      'Remove',
                      style: context.text.body.copyWith(
                        color: context.colors.red,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickPhoto(isLeft),
                    child: Text(
                      'Replace',
                      style: context.text.body.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return kIsWeb
        ? Image.network(
            item.path,
            fit: fit,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(
                Icons.broken_image_rounded,
                color: Colors.white54,
                size: 48,
              ),
            ),
          )
        : Image.file(
            File(mediaRepo.getAbsolutePath(item.path)),
            fit: fit,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(
                Icons.broken_image_rounded,
                color: Colors.white54,
                size: 48,
              ),
            ),
          );
  }

  Widget _buildCompareContent() {
    if (_leftPhoto == null || _rightPhoto == null) {
      return Row(
        children: [
          Expanded(
            child: _leftPhoto == null
                ? _buildEmptySlot(true)
                : _buildPhotoSource(_leftPhoto, true),
          ),
          Expanded(
            child: _rightPhoto == null
                ? _buildEmptySlot(false)
                : _buildPhotoSource(_rightPhoto, false),
          ),
        ],
      );
    }

    if (_mode == CompareMode.sideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickPhoto(true),
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  maxScale: 4.0,
                  child: _buildPhotoSource(_leftPhoto, true),
                ),
              ),
            ),
          ),
          Container(width: 2, color: context.colors.border),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickPhoto(false),
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  maxScale: 4.0,
                  child: _buildPhotoSource(_rightPhoto, false),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Slider Mode
      return GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _sliderPosition += details.delta.dx / context.size!.width;
            _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom photo (Right)
            _buildPhotoSource(_rightPhoto, false, fit: BoxFit.cover),
            // Top photo (Left) clipped
            ClipRect(
              clipper: _SliderClipper(splitFraction: _sliderPosition),
              child: _buildPhotoSource(_leftPhoto, true, fit: BoxFit.cover),
            ),
            // Slider Handle
            Align(
              alignment: FractionalOffset(_sliderPosition, 0.5),
              child: FractionalTranslation(
                translation: const Offset(-0.5, 0.0),
                child: Container(
                  width: 32,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            // Visual divider
            Align(
              alignment: FractionalOffset(_sliderPosition, 0.5),
              child: Container(width: 2, color: Colors.white),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _addPhotoForComparison(bool isLeft) async {
    if (!_ownsPhotos) return;
    final result = await showAppBottomSheet<bool>(
      context: context,
      builder: (_) => const AddProgressPhotoSheet(),
    );
    if (!_ownsPhotos || result != true) return;
    _loadPhotos();
    final other = isLeft ? _rightPhoto : _leftPhoto;
    final candidate = _allPhotos
        .where((photo) => photo.path != other?.path)
        .firstOrNull;
    setState(() {
      if (isLeft) {
        _leftPhoto = candidate;
      } else {
        _rightPhoto = candidate;
      }
    });
  }

  Widget _buildEmptySlot(bool isLeft) {
    final other = isLeft ? _rightPhoto : _leftPhoto;
    final hasUnusedPhoto = _allPhotos.any((photo) => photo.path != other?.path);
    final label = hasUnusedPhoto
        ? 'Choose photo'
        : other != null
        ? 'Add a second photo'
        : 'Add photo';
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () => hasUnusedPhoto
            ? _pickPhoto(isLeft)
            : _addPhotoForComparison(isLeft),
        child: Container(
          color: Colors.black87,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    color: context.colors.textLight.withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.text.body.copyWith(
                      color: context.colors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCaption(PhotoItem? item) {
    if (item == null) return '';
    final String datePart = _formatDateShort(item.date);

    final meta = ref
        .read(mediaRepoProvider)
        .getProgressPhotoMeta(item.date, item.path);
    final log = ref.read(dailyLogRepoProvider).getLog(item.date);

    double? w = meta.weight;
    if (w == null || w == 0.0) {
      w = log?.weight;
    }

    if (w != null && w > 0) {
      final profile = ref.read(profileProvider);
      return '$datePart, ${formatWeight(profile, w)}';
    }
    return datePart;
  }

  @override
  Widget build(BuildContext context) {
    final generation = ref.watch(accountGenerationProvider);
    final changingAccount = ref.watch(accountTransitionProvider);
    if (generation != _accountGeneration || changingAccount) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Compare photos')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Account changed. Reopen your photos for this account.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    ref.watch(profileProvider);
    ref.listen(progressPhotosStreamProvider, (_, _) {
      if (!_ownsPhotos) return;
      _loadPhotos();
      setState(() {
        if (!_allPhotos.any((photo) => photo.path == _leftPhoto?.path)) {
          _leftPhoto = null;
        }
        if (!_allPhotos.any((photo) => photo.path == _rightPhoto?.path)) {
          _rightPhoto = null;
        }
      });
    });
    ref.watch(progressPhotosStreamProvider);

    final wData = _getWeightDelta();
    final weightDeltaText = wData['text'] as String;
    final wColor = wData['color'] as Color?;

    // We render the layout securely inside a RepaintBoundary when we want to be able to share it.
    // The screen wraps it in scaffold.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(17) > 24
            ? 96
            : 64,
        title: Text(
          'Compare photos',
          maxLines: 2,
          style: context.text.cardTitle.copyWith(color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            (MediaQuery.textScalerOf(context).scale(13) > 20 ? 96 : 64) +
                (_mode == CompareMode.slider ? 48 : 0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.screen),
            child: Column(
              children: [
                SegmentedButton<CompareMode>(
                  segments: [
                    ButtonSegment(
                      value: CompareMode.sideBySide,
                      icon: const Icon(Icons.splitscreen_rounded),
                      label: Text(
                        'Side',
                        style: context.text.micro.copyWith(
                          color: _mode == CompareMode.sideBySide
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: CompareMode.slider,
                      icon: const Icon(Icons.compare_arrows_rounded),
                      label: Text(
                        'Slider',
                        style: context.text.micro.copyWith(
                          color: _mode == CompareMode.slider
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (set) {
                    Haptics.tap();
                    setState(() => _mode = set.first);
                    // Reset transform when changing modes
                    _transformController.value = Matrix4.identity();
                  },
                ),
                if (_mode == CompareMode.slider)
                  Slider(
                    value: _sliderPosition,
                    label: '${(_sliderPosition * 100).round()}% first photo',
                    semanticFormatterCallback: (value) =>
                        '${(value * 100).round()} percent first photo',
                    onChanged: (value) =>
                        setState(() => _sliderPosition = value),
                  ),
                const SizedBox(height: Spacing.inline),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Swap photos',
            onPressed: _isSharing ? null : _swapPhotos,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Share comparison',
            onPressed: _isSharing ? null : _shareCompare,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The main scalable exportable view
          RepaintBoundary(
            key: _shareKey,
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  Expanded(child: _buildCompareContent()),
                  // Bottom Dates Banner
                  if (_leftPhoto != null || _rightPhoto != null)
                    Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getCaption(_leftPhoto),
                              textAlign: TextAlign.center,
                              style: AppTheme.numeric(
                                context.text.caption.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _getCaption(_rightPhoto),
                              textAlign: TextAlign.center,
                              style: AppTheme.numeric(
                                context.text.caption.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Floating Pill overlay
          if (_leftPhoto != null &&
              _rightPhoto != null &&
              _getTimeDeltaText().isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              top: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: wColor ?? context.colors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_getTimeDeltaText()}$weightDeltaText',
                    style: AppTheme.numeric(
                      context.text.caption.copyWith(
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double splitFraction;
  _SliderClipper({required this.splitFraction});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * splitFraction, size.height);
  }

  @override
  bool shouldReclip(covariant _SliderClipper oldClipper) {
    return oldClipper.splitFraction != splitFraction;
  }
}
