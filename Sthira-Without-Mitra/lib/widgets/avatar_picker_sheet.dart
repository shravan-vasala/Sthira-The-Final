import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_bottom_sheet.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class AvatarPickerSheet extends StatelessWidget {
  final String? currentAvatar;
  const AvatarPickerSheet({super.key, this.currentAvatar});

  static const List<Map<String, String>> avatars = [
    {'name': 'Lion', 'path': 'assets/avatars/lion.png'},
    {'name': 'Rabbit', 'path': 'assets/avatars/rabbit.png'},
    {'name': 'Owl', 'path': 'assets/avatars/owl.png'},
    {'name': 'Fox', 'path': 'assets/avatars/fox.png'},
    {'name': 'Bear', 'path': 'assets/avatars/bear.png'},
    {'name': 'Panda', 'path': 'assets/avatars/panda.png'},
    {'name': 'Tiger', 'path': 'assets/avatars/tiger.png'},
    {'name': 'Koala', 'path': 'assets/avatars/koala.png'},
    {'name': 'Giraffe', 'path': 'assets/avatars/giraffe.png'},
    {'name': 'Monkey', 'path': 'assets/avatars/monkey.png'},
    {'name': 'Elephant', 'path': 'assets/avatars/elephant.png'},
    {'name': 'Penguin', 'path': 'assets/avatars/penguin.png'},
    {'name': 'Deer', 'path': 'assets/avatars/deer.png'},
    {'name': 'Red Panda', 'path': 'assets/avatars/red_panda.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Sthira Spirit',
      subtitle: 'Select your companion',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
            ),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              final isSelected = avatar['path'] == currentAvatar;
              return Semantics(
                button: true,
                selected: isSelected,
                label: 'Select ${avatar['name']}',
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(avatar['path']),
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: context.colors.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            avatar['path']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: context.colors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: Spacing.section),

          // Remove Avatar Action
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop('DELETE'),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textMedium,
                minimumSize: const Size(44, 44),
              ),
              child: Text(
                'Remove Avatar',
                style: context.text.bodyStrong.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
