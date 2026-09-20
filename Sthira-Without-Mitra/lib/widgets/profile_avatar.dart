import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Resolves stored media in the current account and never leaves a broken image.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.photoPath,
    this.size = 44,
  });

  final String name;
  final String? photoPath;
  final double size;

  Widget _fallback(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? ''
        : [
            words.first,
            if (words.length > 1) words.last,
          ].map((word) => word.characters.first.toUpperCase()).join();
    return ColoredBox(
      key: const ValueKey('profile-avatar-fallback'),
      color: context.colors.insetSurface,
      child: Center(
        child: initials.isEmpty
            ? Icon(
                Icons.person_outline_rounded,
                color: context.colors.textMedium,
                size: size * .5,
              )
            : Padding(
                padding: EdgeInsets.all(size * .15),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    initials,
                    style:
                        (size >= 64
                                ? context.text.display
                                : context.text.bodyStrong)
                            .copyWith(color: context.colors.accentText),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generation = ref.watch(accountGenerationProvider);
    final transitioning = ref.watch(accountTransitionProvider);
    final path = photoPath?.trim();
    final isPreset = path?.startsWith('assets/avatars/') == true;
    ImageProvider? image;
    if (!transitioning && path != null && path.isNotEmpty) {
      if (path.startsWith('assets/')) {
        image = AssetImage(path);
      } else {
        final media = ref.watch(mediaRepoProvider);
        try {
          final resolved = media.getAbsolutePath(path);
          image = kIsWeb ? NetworkImage(resolved) : FileImage(File(resolved));
        } on Object {
          // Missing/restored media must not prevent opening the profile.
        }
      }
    }
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: image == null
              ? _fallback(context)
              : Image(
                  key: ValueKey('$generation:$path'),
                  image: image,
                  width: size,
                  height: size,
                  fit: isPreset ? BoxFit.contain : BoxFit.cover,
                  gaplessPlayback: false,
                  frameBuilder: (context, child, frame, synchronous) {
                    if (frame == null && !synchronous) {
                      return _fallback(context);
                    }
                    // Preset ears and antlers need room inside the circle.
                    // Photos still fill the frame without an artificial inset.
                    return isPreset
                        ? Padding(
                            padding: EdgeInsets.all(size * .08),
                            child: child,
                          )
                        : child;
                  },
                  errorBuilder: (context, error, stack) => _fallback(context),
                ),
        ),
      ),
    );
  }
}
