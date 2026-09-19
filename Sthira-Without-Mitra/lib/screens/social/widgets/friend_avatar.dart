import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/profile_avatar.dart';

/// Shared profiles support bundled presets; device-local media stays local.
class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 40,
  });
  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = avatarUrl?.trim();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.border),
      ),
      padding: const EdgeInsets.all(1),
      child: ProfileAvatar(
        name: name,
        photoPath: path?.startsWith('assets/') == true ? path : null,
        size: size,
      ),
    );
  }
}
