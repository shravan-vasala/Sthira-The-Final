import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/empty_state_view.dart';
import '../../services/haptics.dart';
import 'widgets/add_progress_photo_sheet.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import 'photo_compare_screen.dart';
import 'photo_viewer_screen.dart';
import '../../theme/layout_insets.dart';
import '../../utils/format_units.dart';

class PhysiquePicturesScreen extends ConsumerStatefulWidget {
  const PhysiquePicturesScreen({super.key});

  @override
  ConsumerState<PhysiquePicturesScreen> createState() =>
      _PhysiquePicturesScreenState();
}

class _PhysiquePicturesScreenState
    extends ConsumerState<PhysiquePicturesScreen> {
  bool _isSelectionMode = false;
  bool _isDeleting = false;
  final Set<String> _selectedPhotos = {};
  String _currentFilter = 'all';
  int? _displayedGeneration;

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPhotos.contains(path)) {
        _selectedPhotos.remove(path);
        if (_selectedPhotos.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPhotos.add(path);
      }
    });
  }

  void _deleteSelected(Map<String, List<String>> photosByDate) {
    if (_selectedPhotos.isEmpty || _isDeleting) return;
    final selected = Set<String>.from(_selectedPhotos);
    final generation = ref.read(accountGenerationProvider);

    showAppBottomSheet(
      context: context,
      builder: (ctx) => AppSheet(
        title: 'Delete Photos?',
        subtitle: 'Delete ${selected.length} photo(s)? This can\'t be undone.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              onPressed: _isDeleting
                  ? null
                  : () async {
                      if (!mounted ||
                          ref.read(accountGenerationProvider) != generation ||
                          ref.read(accountTransitionProvider)) {
                        Navigator.pop(ctx);
                        return;
                      }
                      Navigator.pop(ctx);
                      setState(() => _isDeleting = true);
                      final toDelete = <String, List<String>>{};
                      for (final path in selected) {
                        for (final entry in photosByDate.entries) {
                          if (entry.value.contains(path)) {
                            toDelete.putIfAbsent(entry.key, () => []).add(path);
                            break;
                          }
                        }
                      }
                      try {
                        await ref
                            .read(mediaRepoProvider)
                            .deletePhotos(toDelete);
                        if (mounted &&
                            generation == ref.read(accountGenerationProvider)) {
                          setState(() {
                            _selectedPhotos.clear();
                            _isSelectionMode = false;
                            _isDeleting = false;
                          });
                        }
                      } catch (e) {
                        if (mounted &&
                            generation == ref.read(accountGenerationProvider)) {
                          setState(() => _isDeleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Could not delete photos. Your selection is kept; try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              label: 'Delete',
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: context.text.body.copyWith(
                  color: context.colors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final generation = ref.watch(accountGenerationProvider);
    final changingAccount = ref.watch(accountTransitionProvider);
    final profile = ref.watch(profileProvider);
    if (_displayedGeneration != generation) {
      _displayedGeneration = generation;
      _selectedPhotos.clear();
      _isSelectionMode = false;
      _isDeleting = false;
      _currentFilter = 'all';
    }
    if (changingAccount) {
      return Scaffold(
        appBar: AppBar(title: const Text('Physique Pictures')),
        body: const Center(child: Text('Changing account...')),
      );
    }
    ref.watch(progressPhotosStreamProvider);
    final mediaRepo = ref.watch(mediaRepoProvider);
    final rawPhotos = mediaRepo.getAllProgressPhotos();

    // Filter the photos based on _currentFilter
    final allPhotos = <MapEntry<String, List<String>>>[];
    for (final entry in rawPhotos) {
      final date = entry.key;
      final filteredPaths = <String>[];
      for (final path in entry.value) {
        final meta = mediaRepo.getProgressPhotoMeta(date, path);
        if (_currentFilter == 'all' || meta.pose == _currentFilter) {
          filteredPaths.add(path);
        }
      }
      if (filteredPaths.isNotEmpty) {
        allPhotos.add(MapEntry(date, filteredPaths));
      }
    }

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedPhotos.length} Selected'
              : 'Physique Pictures',
        ),
        leading: IconButton(
          tooltip: _isSelectionMode ? 'Cancel selection' : 'Back',
          icon: Icon(
            _isSelectionMode ? Icons.close_rounded : Icons.arrow_back_rounded,
          ),
          onPressed: () {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedPhotos.clear();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              tooltip: 'Delete selected photos',
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.colors.red,
              ),
              onPressed: _isDeleting
                  ? null
                  : () {
                      final Map<String, List<String>> photosByDate = {};
                      for (final entry in rawPhotos) {
                        photosByDate[entry.key] = entry.value;
                      }
                      _deleteSelected(photosByDate);
                    },
            )
          else if (allPhotos.isNotEmpty)
            TextButton.icon(
              onPressed: () => _openCompareMode(allPhotos),
              icon: Icon(Icons.compare_rounded, color: context.colors.primary),
              label: Text(
                'Compare',
                style: context.text.body.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: rawPhotos.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: shellFloatingActionBottomPadding(context),
              ),
              child: FloatingActionButton.extended(
                onPressed: _addPhoto,
                backgroundColor: context.colors.primary,
                icon: Icon(
                  Icons.add_a_photo_rounded,
                  color: context.colors.onPrimary,
                ),
                label: Text(
                  'Add photo',
                  style: context.text.body.copyWith(
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            ),
      body: Column(
        children: [
          // Filter Toggle
          if (rawPhotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _FilterChip(
                      label:
                          'All · ${rawPhotos.fold<int>(0, (p, c) => p + c.value.length)}',
                      isSelected: _currentFilter == 'all',
                      onTap: () {
                        Haptics.tap();
                        setState(() => _currentFilter = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:
                          'Front · ${rawPhotos.fold<int>(0, (p, c) => p + c.value.where((ph) => ref.read(mediaRepoProvider).getPoseTag(ph) == 'front').length)}',
                      isSelected: _currentFilter == 'front',
                      onTap: () {
                        Haptics.tap();
                        setState(() => _currentFilter = 'front');
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:
                          'Side · ${rawPhotos.fold<int>(0, (p, c) => p + c.value.where((ph) => ref.read(mediaRepoProvider).getPoseTag(ph) == 'side').length)}',
                      isSelected: _currentFilter == 'side',
                      onTap: () {
                        Haptics.tap();
                        setState(() => _currentFilter = 'side');
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:
                          'Back · ${rawPhotos.fold<int>(0, (p, c) => p + c.value.where((ph) => ref.read(mediaRepoProvider).getPoseTag(ph) == 'back').length)}',
                      isSelected: _currentFilter == 'back',
                      onTap: () {
                        Haptics.tap();
                        setState(() => _currentFilter = 'back');
                      },
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: rawPhotos.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final bottomPadding = shellScrollBottomPadding(context);
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: bottomPadding),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight > bottomPadding
                                ? constraints.maxHeight - bottomPadding
                                : 0,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const EmptyStateView(
                                  icon: Icons.photo_library_outlined,
                                  title: 'No progress photos yet',
                                  subtitle:
                                      'Add your first photo to track your journey.',
                                ),
                                const SizedBox(height: Spacing.section),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Spacing.screen,
                                  ),
                                  child: PrimaryButton(
                                    label: 'Take First Photo',
                                    onPressed: _openCamera,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : allPhotos.isEmpty
                ? Center(
                    child: Text(
                      'No photos for this pose.',
                      style: context.text.body.copyWith(
                        color: context.colors.textMedium,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      Spacing.screen,
                      Spacing.stack,
                      Spacing.screen,
                      // Clear the 56px extended action and its gap as well as the dock.
                      shellScrollBottomPadding(context) + 56 + Spacing.block,
                    ),
                    itemCount: allPhotos.length,
                    itemBuilder: (context, index) {
                      final entry = allPhotos[index];
                      final date = entry.key;
                      final photos = entry.value;
                      final formattedDate = _formatDate(date);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              formattedDate,
                              style: AppTheme.numeric(
                                context.text.bodyStrong.copyWith(
                                  color: context.colors.textDark,
                                ),
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: photos.length,
                            itemBuilder: (context, i) {
                              final photoPath = photos[i];
                              final meta = ref
                                  .read(mediaRepoProvider)
                                  .getProgressPhotoMeta(date, photoPath);
                              final poseTag = meta.pose;
                              final weight = meta.weight;

                              final isSelected = _selectedPhotos.contains(
                                photoPath,
                              );

                              return GestureDetector(
                                key: ValueKey('progress-photo-$photoPath'),
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    setState(() {
                                      _isSelectionMode = true;
                                      _selectedPhotos.add(photoPath);
                                    });
                                  }
                                },
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(photoPath);
                                  } else {
                                    _openViewer(allPhotos, index, i);
                                  }
                                },
                                child: Semantics(
                                  label:
                                      '${poseTag == 'none' ? 'Progress' : poseTag} photo, $formattedDate',
                                  selected: isSelected,
                                  button: true,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Hero(
                                          tag: photoPath,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              Radii.chip,
                                            ),
                                            child: kIsWeb
                                                ? Image.network(
                                                    photoPath,
                                                    fit: BoxFit.cover,
                                                    cacheWidth: 400,
                                                    errorBuilder: (_, e, s) =>
                                                        Container(
                                                          color: context
                                                              .colors
                                                              .lavender,
                                                          child: Icon(
                                                            Icons
                                                                .broken_image_rounded,
                                                            color: context
                                                                .colors
                                                                .textLight,
                                                          ),
                                                        ),
                                                  )
                                                : Image.file(
                                                    File(
                                                      ref
                                                          .read(
                                                            mediaRepoProvider,
                                                          )
                                                          .getAbsolutePath(
                                                            photoPath,
                                                          ),
                                                    ),
                                                    fit: BoxFit.cover,
                                                    cacheWidth: 400,
                                                    errorBuilder: (_, e, s) =>
                                                        Container(
                                                          color: context
                                                              .colors
                                                              .lavender,
                                                          child: Icon(
                                                            Icons
                                                                .broken_image_rounded,
                                                            color: context
                                                                .colors
                                                                .textLight,
                                                          ),
                                                        ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      if (poseTag != 'none')
                                        Positioned(
                                          bottom: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.colors.textDark
                                                  .withValues(alpha: 0.6),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    Radii.micro,
                                                  ),
                                            ),
                                            child: Text(
                                              poseTag.toUpperCase(),
                                              style: context.text.micro
                                                  .copyWith(
                                                    color: context
                                                        .colors
                                                        .onPrimary,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      if (weight != null)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          left: 4,
                                          child: Align(
                                            alignment: Alignment.topRight,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: context.colors.primary
                                                    .withValues(alpha: 0.8),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      Radii.micro,
                                                    ),
                                              ),
                                              child: Text(
                                                formatWeight(profile, weight),
                                                style: AppTheme.numeric(
                                                  context.text.micro.copyWith(
                                                    color: context
                                                        .colors
                                                        .onPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (isSelected)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: context.colors.primary
                                                  .withValues(alpha: 0.4),
                                              borderRadius:
                                                  BorderRadius.circular(
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
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPhoto() async {
    final result = await showAppBottomSheet<bool>(
      context: context,
      builder: (_) => const AddProgressPhotoSheet(),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  void _openCamera() {
    _addPhoto();
  }

  Future<void> _openViewer(
    List<MapEntry<String, List<String>>> allPhotos,
    int dateIndex,
    int photoIndex,
  ) async {
    final flatPhotos = <PhotoItem>[];
    int targetIndex = 0;
    for (int i = 0; i < allPhotos.length; i++) {
      final date = allPhotos[i].key;
      for (int j = 0; j < allPhotos[i].value.length; j++) {
        final path = allPhotos[i].value[j];
        final meta = ref
            .read(mediaRepoProvider)
            .getProgressPhotoMeta(date, path);
        flatPhotos.add(PhotoItem(path: path, date: date, poseTag: meta.pose));
        if (i == dateIndex && j == photoIndex) {
          targetIndex = flatPhotos.length - 1;
        }
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PhotoViewerScreen(photos: flatPhotos, initialIndex: targetIndex),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _openCompareMode(List<MapEntry<String, List<String>>> allPhotos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhotoCompareScreen()),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primary
                : context.colors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: context.text.caption.copyWith(
              color: isSelected
                  ? context.colors.onPrimary
                  : context.colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
