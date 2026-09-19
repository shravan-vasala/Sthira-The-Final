import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/badge_engine_provider.dart';
import '../providers/account_scope_provider.dart';
import '../models/badge.dart';
import '../services/haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_motion.dart';

class BadgeOverlayHost extends ConsumerStatefulWidget {
  const BadgeOverlayHost({super.key});

  @override
  ConsumerState<BadgeOverlayHost> createState() => _BadgeOverlayHostState();
}

class _BadgeOverlayHostState extends ConsumerState<BadgeOverlayHost>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  Badge? _currentBadge;
  Timer? _hideTimer;
  Timer? _nextTimer;
  bool _isShowing = false;
  bool _isDismissing = false;
  bool _foreground = true;
  bool _available = false;
  bool _focused = false;
  bool _hovered = false;
  int _presentationId = 0;
  int _shownAccountGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _controller = AnimationController(
      vsync: this,
      duration: Motion.deliberate,
      reverseDuration: Motion.standard,
    );
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Motion.enter,
      reverseCurve: Motion.exit,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = reduceMotion ? Duration.zero : Motion.deliberate;
    _controller.reverseDuration = reduceMotion
        ? Duration.zero
        : Motion.standard;
    _updateAvailability();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _updateAvailability();
  }

  void _updateAvailability() {
    final available =
        _foreground &&
        ModalRoute.of(context)?.isCurrent != false &&
        TickerMode.valuesOf(context).enabled &&
        !ref.read(accountTransitionProvider) &&
        !ref.read(accountHydratingProvider);
    if (_available != available) {
      _available = available;
      if (!available) {
        _hideTimer?.cancel();
        _nextTimer?.cancel();
        _hideTimer = null;
        _nextTimer = null;
      }
      setState(() {});
    }
    if (available) {
      _scheduleHide();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _processQueue();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presentationId++;
    _hideTimer?.cancel();
    _nextTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _clearOverlay() {
    _presentationId++;
    _hideTimer?.cancel();
    _nextTimer?.cancel();
    _hideTimer = null;
    _nextTimer = null;
    _controller.reset();
    if (!mounted) return;
    setState(() {
      _currentBadge = null;
      _isShowing = false;
      _isDismissing = false;
      _focused = false;
      _hovered = false;
    });
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!_available ||
        !_isShowing ||
        _isDismissing ||
        _focused ||
        _hovered ||
        MediaQuery.accessibleNavigationOf(context)) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 5), _dismissBadge);
  }

  void _processQueue() {
    if (!mounted || !_available || _isShowing || _nextTimer != null) return;
    final queue = ref.read(badgeUnlockEventProvider);
    if (queue.isEmpty) return;
    _presentationId++;
    _shownAccountGeneration = ref.read(accountGenerationProvider);
    setState(() {
      _isShowing = true;
      _isDismissing = false;
      _currentBadge = queue.first;
    });
    Haptics.success();
    _controller.forward(from: 0);
    _scheduleHide();
  }

  Future<void> _dismissBadge() async {
    if (!mounted || _currentBadge == null || _isDismissing) return;
    _isDismissing = true;
    _hideTimer?.cancel();
    _hideTimer = null;
    final presentation = _presentationId;
    final accountGeneration = _shownAccountGeneration;
    final badgeId = _currentBadge!.id;
    try {
      await _controller.reverse().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted ||
        presentation != _presentationId ||
        accountGeneration != ref.read(accountGenerationProvider)) {
      return;
    }
    final queue = ref.read(badgeUnlockEventProvider);
    if (queue.isEmpty || queue.first.id != badgeId) {
      _clearOverlay();
      return;
    }
    setState(() {
      _currentBadge = null;
      _isShowing = false;
      _isDismissing = false;
      _focused = false;
      _hovered = false;
    });
    _nextTimer?.cancel();
    _nextTimer = Timer(
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Motion.deliberate,
      () {
        _nextTimer = null;
        if (mounted &&
            presentation == _presentationId &&
            accountGeneration == ref.read(accountGenerationProvider)) {
          _processQueue();
        }
      },
    );
    ref.read(badgeUnlockEventProvider.notifier).dequeue();
  }

  void _viewTrophies() {
    if (_shownAccountGeneration != ref.read(accountGenerationProvider) ||
        !_available) {
      return;
    }
    _clearOverlay();
    // All pending trophies are visible on Profile; do not cover that destination.
    ref.read(badgeUnlockEventProvider.notifier).clear();
    context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountGenerationProvider, (previous, next) {
      if (previous != next) _clearOverlay();
    });
    ref.listen(accountTransitionProvider, (_, _) => _updateAvailability());
    ref.listen(accountHydratingProvider, (_, _) => _updateAvailability());
    ref.listen<List<Badge>>(badgeUnlockEventProvider, (previous, next) {
      if (next.isEmpty ||
          (_currentBadge != null && next.first.id != _currentBadge!.id)) {
        _clearOverlay();
      }
      if (next.isNotEmpty && !_isShowing && _nextTimer == null) _processQueue();
    });
    final badge = _currentBadge;
    if (badge == null || !_available) return const SizedBox.shrink();
    final badges = ref.watch(badgesProvider);
    final unlockedCount = badges.where((item) => item.isUnlocked).length;

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -150 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: Focus(
          onFocusChange: (value) {
            _focused = value;
            _scheduleHide();
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _dismissBadge();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            onEnter: (_) {
              _hovered = true;
              _scheduleHide();
            },
            onExit: (_) {
              _hovered = false;
              _scheduleHide();
            },
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < -2) _dismissBadge();
              },
              child: Semantics(
                container: true,
                liveRegion: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                        decoration: BoxDecoration(
                          color: context.colors.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.gold.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                (MediaQuery.sizeOf(context).height -
                                        MediaQuery.paddingOf(context).vertical -
                                        48)
                                    .clamp(80.0, double.infinity),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ExcludeSemantics(
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              context.colors.goldMuted,
                                              context.colors.gold,
                                            ],
                                            radius: 0.8,
                                          ),
                                          border: Border.all(
                                            color: context.colors.gold,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          badge.iconEmoji,
                                          style: context.text.cardTitle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Achievement unlocked',
                                            style: context.text.micro.copyWith(
                                              color: context.colors.accentText,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            badge.title,
                                            style: context.text.cardTitle
                                                .copyWith(
                                                  color:
                                                      context.colors.textDark,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Dismiss achievement',
                                      onPressed: _dismissBadge,
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  badge.description,
                                  style: context.text.caption.copyWith(
                                    color: context.colors.textMedium,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '$unlockedCount of ${badges.length} unlocked',
                                      style: context.text.micro.copyWith(
                                        color: context.colors.textMedium,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _viewTrophies,
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(48, 48),
                                      ),
                                      child: const Text('View trophies'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
