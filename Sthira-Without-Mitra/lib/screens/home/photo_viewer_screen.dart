import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../utils/format_units.dart';

class PhotoItem {
  final String path;
  final String date;
  final String poseTag;

  PhotoItem({required this.path, required this.date, required this.poseTag});
}

class PhotoViewerScreen extends ConsumerStatefulWidget {
  final List<PhotoItem> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<PhotoItem> _photos;
  bool _showOverlay = true;
  bool _isZoomed = false;
  bool _isDeleting = false;
  late final int _accountGeneration;
  bool get _ownsPhotos =>
      mounted &&
      ref.read(accountGenerationProvider) == _accountGeneration &&
      !ref.read(accountTransitionProvider);

  @override
  void initState() {
    super.initState();
    _accountGeneration = ref.read(accountGenerationProvider);
    _photos = List.from(widget.photos);
    _currentIndex = _photos.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _deleteCurrentPhoto() {
    if (_isDeleting || !_ownsPhotos || _photos.isEmpty) return;
    final item = _photos[_currentIndex];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isDeleting
                ? null
                : () async {
                    Navigator.pop(ctx);
                    if (!_ownsPhotos) return;

                    setState(() => _isDeleting = true);

                    try {
                      await ref
                          .read(mediaRepoProvider)
                          .deletePhoto(item.date, item.path);
                    } catch (e) {
                      if (mounted && _ownsPhotos) {
                        setState(() => _isDeleting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete photo: $e')),
                        );
                      }
                      return;
                    }

                    if (!mounted || !_ownsPhotos) return;

                    final updatedPhotos = List<PhotoItem>.from(_photos)
                      ..removeWhere((p) => p.path == item.path);

                    if (updatedPhotos.isEmpty) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _photos = updatedPhotos;
                        _isDeleting = false;
                        if (_currentIndex >= _photos.length) {
                          _currentIndex = _photos.length - 1;
                        }
                      });
                      _pageController.jumpToPage(_currentIndex);
                    }
                  },
            child: Text(
              'Delete',
              style: context.text.body.copyWith(color: context.colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _poseLabel(String tag) {
    if (tag == 'none' || tag.isEmpty) return '';
    switch (tag) {
      case 'front':
        return 'Front';
      case 'side':
        return 'Side';
      case 'back':
        return 'Back';
      default:
        return tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final generation = ref.watch(accountGenerationProvider);
    final changingAccount = ref.watch(accountTransitionProvider);
    if (generation != _accountGeneration || changingAccount) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Progress photo')),
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
    final profile = ref.watch(profileProvider);
    if (_photos.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final currentPhoto = _photos[_currentIndex];
    final metadata = ref
        .watch(mediaRepoProvider)
        .getProgressPhotoMeta(currentPhoto.date, currentPhoto.path);
    final note = metadata.note?.trim() ?? '';
    final weight = metadata.weight;
    final poseLabel = _poseLabel(currentPhoto.poseTag);
    final dateLabel = _formatDate(currentPhoto.date);

    final titleText = poseLabel.isNotEmpty
        ? '$dateLabel · $poseLabel'
        : dateLabel;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          children: [
            Dismissible(
              key: const Key('viewer_dismiss'),
              direction: DismissDirection.vertical,
              onDismissed: (_) => Navigator.pop(context),
              child: PageView.builder(
                controller: _pageController,
                physics: _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  return _ZoomablePhoto(
                    photoPath: _photos[index].path,
                    onZoomStateChanged: (zoomed) {
                      if (_isZoomed != zoomed) {
                        setState(() => _isZoomed = zoomed);
                      }
                    },
                  );
                },
              ),
            ),

            if (_showOverlay &&
                ((weight != null && weight > 0) || note.isNotEmpty))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .3,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (weight != null && weight > 0)
                                Text(
                                  formatWeight(profile, weight),
                                  style: context.text.bodyStrong.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              if (note.isNotEmpty) ...[
                                if (weight != null && weight > 0)
                                  const SizedBox(height: 8),
                                Text(
                                  note,
                                  style: context.text.body.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Top Overlay
            if (_showOverlay)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              titleText,
                              style: context.text.cardTitle.copyWith(
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _deleteCurrentPhoto,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomablePhoto extends ConsumerStatefulWidget {
  final String photoPath;
  final ValueChanged<bool> onZoomStateChanged;

  const _ZoomablePhoto({
    required this.photoPath,
    required this.onZoomStateChanged,
  });

  @override
  ConsumerState<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends ConsumerState<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  bool _wasZoomed = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Motion.standard)
          ..addListener(() {
            if (_animation != null) {
              _transformationController.value = _animation!.value;
            }
          });
    _transformationController.addListener(_onScaleChanged);
  }

  void _onScaleChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.05;
    if (_wasZoomed != isZoomed) {
      _wasZoomed = isZoomed;
      widget.onZoomStateChanged(isZoomed);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;

    final Matrix4 endMatrix;
    if (_transformationController.value.isIdentity()) {
      final position = _doubleTapDetails!.localPosition;
      // Zoom in
      endMatrix = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(-position.dx, -position.dy)
        // ignore: deprecated_member_use
        ..scale(2.5);
    } else {
      // Zoom out to normal
      endMatrix = Matrix4.identity();
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Motion.enter).animate(_animationController));

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: Hero(
            tag: widget.photoPath, // Optional: if we want to do hero animations
            child: kIsWeb
                ? Image.network(
                    widget.photoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 40,
                    ),
                  )
                : Image.file(
                    File(
                      ref
                          .read(mediaRepoProvider)
                          .getAbsolutePath(widget.photoPath),
                    ),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
