import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/layout_insets.dart';
import 'widgets/activity_heatmap.dart';

class YearlyActivityScreen extends StatelessWidget {
  const YearlyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.scaffoldBg,
    appBar: AppBar(
      centerTitle: false,
      toolbarHeight: MediaQuery.textScalerOf(context).scale(24) > 36 ? 104 : 64,
      title: Text(
        'Yearly activity',
        maxLines: 2,
        style: context.text.screenTitle,
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const ValueKey('yearly-activity-scroll'),
        padding: EdgeInsets.fromLTRB(
          Spacing.screen,
          Spacing.inline,
          Spacing.screen,
          shellScrollBottomPadding(context),
        ),
        child: const ActivityHeatmap(),
      ),
    ),
  );
}
