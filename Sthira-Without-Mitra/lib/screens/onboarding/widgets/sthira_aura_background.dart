import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_motion.dart';

class SthiraAuraBackground extends StatelessWidget {
  final int currentPage;

  const SthiraAuraBackground({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final Color primaryAura = context.colors.surface;
    final Color secondaryAura = context.colors.surface;
    final Color baseBg = context.colors.scaffoldBg;

    return Container(
      decoration: BoxDecoration(
        color: baseBg,
        gradient: RadialGradient(
          center: const Alignment(0, 0.2),
          radius: 1.2,
          colors: [
            primaryAura.withValues(alpha: 0.8),
            secondaryAura.withValues(alpha: 0.3),
            baseBg,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: Motion.deliberate,
            curve: Motion.enter,
            top: currentPage == 0
                ? -150
                : (currentPage == 1 ? -50 : (currentPage == 2 ? 100 : -100)),
            right: currentPage == 0
                ? -50
                : (currentPage == 1 ? 150 : (currentPage == 2 ? -100 : 50)),
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryAura.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
