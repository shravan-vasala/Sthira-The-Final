import 'package:flutter/material.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/setup_sheets.dart';
import '../../../widgets/primary_button.dart';

class SocialSignInPrompt extends StatelessWidget {
  const SocialSignInPrompt({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(Spacing.screen),
    child: Column(
      children: [
        const SizedBox(height: Spacing.major),
        Icon(
          Icons.people_outline_rounded,
          size: 48,
          color: context.colors.accentText,
        ),
        const SizedBox(height: Spacing.section),
        Text(
          'Connect with your people',
          textAlign: TextAlign.center,
          style: context.text.cardTitle,
        ),
        const SizedBox(height: Spacing.stack),
        Text(
          'Sign in to exchange friend IDs and share activity with people you accept.',
          textAlign: TextAlign.center,
          style: context.text.body.copyWith(color: context.colors.textMedium),
        ),
        const SizedBox(height: Spacing.section),
        PrimaryButton(
          label: 'Sign in',
          onPressed: () => showAppBottomSheet(
            context: context,
            builder: (_) => const CloudSyncSheet(),
          ),
        ),
      ],
    ),
  );
}
