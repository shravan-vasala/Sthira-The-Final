import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import '../../../widgets/surface_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../widgets/gita_verse_sheet.dart';
import '../../../theme/app_motion.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: Motion.deliberate,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _staggerController.value = 1.0;
    } else if (!_staggerController.isAnimating &&
        _staggerController.value == 0) {
      _staggerController.forward();
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: Spacing.major),
            // Logo Entrance
            AnimatedBuilder(
              animation: _staggerController,
              builder: (context, child) {
                final scale = CurvedAnimation(
                  parent: _staggerController,
                  curve: const Interval(0.0, 0.4, curve: Motion.enter),
                ).value;
                final fade = CurvedAnimation(
                  parent: _staggerController,
                  curve: const Interval(0.0, 0.3, curve: Motion.exit),
                ).value;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final assetName = isDark 
                    ? 'assets/welcome/sunflower-welcome-dark-512.png'
                    : 'assets/welcome/sunflower-welcome-light-512.png';
                Widget logo = Image.asset(
                  assetName,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                );
                if (!MediaQuery.disableAnimationsOf(context)) {
                  logo = logo
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 4.seconds,
                        color: Colors.white.withValues(alpha: 0.1),
                      );
                }
                return Opacity(
                  opacity: fade,
                  child: Transform.scale(scale: scale, child: logo),
                );
              },
            ),
            const SizedBox(height: Spacing.section),
            // Title
            AnimatedBuilder(
              animation: _staggerController,
              builder: (context, child) {
                final fade = CurvedAnimation(
                  parent: _staggerController,
                  curve: const Interval(0.2, 0.5, curve: Motion.exit),
                ).value;
                return Opacity(
                  opacity: fade,
                  child: Column(
                    children: [
                      Text(
                        'Sthira',
                        style: context.text.display.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                      const SizedBox(height: Spacing.stack),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'स्थिर',
                            style: context.text.screenTitle.copyWith(
                              color: const Color(0xFFE29B65),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '•',
                              style: context.text.bodyStrong.copyWith(
                                color: context.colors.textLight,
                              ),
                            ),
                          ),
                          Text(
                            'steady, every day',
                            style: context.text.bodyStrong.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: Spacing.major),

            // Pillars
            _buildAnimPill(
              delayIdx: 0,
              icon: Icons.offline_bolt_rounded,
              title: 'Local-first',
              subtitle: 'Your saved plans and logs work offline.',
            ),
            _buildAnimPill(
              delayIdx: 1,
              icon: Icons.camera_alt_rounded,
              title: 'AI Food Scanning',
              subtitle:
                  'Review meal estimates from a photo. Internet required.',
            ),
            _buildAnimPill(
              delayIdx: 2,
              icon: Icons.security_rounded,
              title: 'Your data, yours',
              subtitle: 'Export or encrypted backup anytime.',
            ),

            const SizedBox(height: Spacing.major),

            // 2:47 Easter Egg
            AnimatedBuilder(
              animation: _staggerController,
              builder: (context, child) {
                final fade = CurvedAnimation(
                  parent: _staggerController,
                  curve: const Interval(0.7, 1.0, curve: Motion.exit),
                ).value;
                return Opacity(
                  opacity: fade,
                  child: const GitaReflectionButton(),
                );
              },
            ),
            const SizedBox(height: Spacing.textPair),
            // Dedication
            AnimatedBuilder(
              animation: _staggerController,
              builder: (context, child) {
                final fade = CurvedAnimation(
                  parent: _staggerController,
                  curve: const Interval(0.8, 1.0, curve: Motion.exit),
                ).value;
                return Opacity(opacity: fade, child: const _DedicationLine());
              },
            ),
            const SizedBox(height: Spacing.major),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimPill({
    required int delayIdx,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final start = 0.4 + (delayIdx * 0.1);
    final end = start + 0.3;
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        final slide = CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Motion.enter),
        ).value;
        final fade = CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end - 0.1, curve: Motion.exit),
        ).value;
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - slide)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Builder(
                builder: (context) {
                  Widget card = SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: context.colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: context.text.bodyStrong.copyWith(
                                  color: context.colors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: context.text.caption.copyWith(
                                  color: context.colors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  if (!MediaQuery.disableAnimationsOf(context)) {
                    card = card
                        .animate(
                          delay: (start * 1000 + 1000).ms,
                          onPlay: (controller) =>
                              controller.repeat(reverse: false),
                        )
                        .shimmer(
                          duration: 3.seconds,
                          color: Colors.white.withValues(alpha: 0.05),
                        );
                  }
                  return card;
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DedicationLine extends StatelessWidget {
  const _DedicationLine();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Made with ',
          style: context.text.micro.copyWith(color: context.colors.textLight),
        ),
        Icon(
          Icons.favorite_rounded,
          color: context.colors.primary.withValues(alpha: 0.8),
          size: IconSize.inline,
        ),
        Text(
          ' for Bodamma',
          style: context.text.micro.copyWith(color: context.colors.textLight),
        ),
      ],
    );
  }
}

class CompletionScreen extends StatefulWidget {
  final String name;
  final VoidCallback onComplete;

  const CompletionScreen({
    super.key,
    required this.name,
    required this.onComplete,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  bool _sequenceStarted = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Motion.deliberate,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sequenceStarted) {
      _sequenceStarted = true;
      _playSequence(MediaQuery.disableAnimationsOf(context));
    }
  }

  Future<void> _playSequence(bool disableAnim) async {
    if (disableAnim) {
      _fadeController.value = 1.0;
      await Future.delayed(Motion.instant);
      if (!mounted) return;
      widget.onComplete();
      return;
    }

    await Future.delayed(Motion.instant);
    if (!mounted) return;
    await _fadeController.forward();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: CurvedAnimation(
                    parent: _fadeController,
                    curve: const Interval(0.0, 0.4, curve: Motion.exit),
                  ).value,
                  child: Text(
                    widget.name.isEmpty
                        ? 'Your journey starts now.'
                        : 'Your journey starts now,\n${widget.name}.',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.display.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Opacity(
                  opacity: CurvedAnimation(
                    parent: _fadeController,
                    curve: const Interval(0.6, 1.0, curve: Motion.exit),
                  ).value,
                  child: const _DedicationLine(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
