import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class OfflineBanner extends StatelessWidget {
  final String message;

  const OfflineBanner({
    super.key,
    this.message =
        'You are offline. AI scanning needs a connection. Saved meals stay available.',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: context.colors.orange.withValues(alpha: 0.15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.wifi_off_rounded,
                color: context.colors.accentText,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: context.text.caption.copyWith(
                  color: context.colors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
