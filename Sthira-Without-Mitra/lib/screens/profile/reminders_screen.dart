import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/account_scope_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/settings_row.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/layout_insets.dart';
import '../../theme/app_motion.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initialTime,
    Function(TimeOfDay) onPicked,
  ) async {
    final generation = ref.read(accountGenerationProvider);
    final parentTheme = Theme.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(
          data: parentTheme.copyWith(
            colorScheme: parentTheme.colorScheme.copyWith(
              primary: context.colors.primary,
              onPrimary: context.colors.onPrimary,
              onSurface: context.colors.textDark,
            ),
          ),
          child: child,
        );
      },
    );
    if (mounted &&
        picked != null &&
        generation == ref.read(accountGenerationProvider)) {
      onPicked(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remindersProvider);
    final error = ref.watch(reminderErrorProvider);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Reminders'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Spacing.screen,
          Spacing.section,
          Spacing.screen,
          shellScrollBottomPadding(context),
        ),
        children: [
          if (error != null) ...[
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(Spacing.cardPad),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(Radii.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error,
                      style: context.text.body.copyWith(
                        color: context.colors.textDark,
                      ),
                    ),
                    if (!error.contains('permission'))
                      TextButton(
                        onPressed: () =>
                            ref.read(remindersProvider.notifier).queueSync(),
                        child: const Text('Retry scheduling'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.section),
          ],
          _buildSectionHeader('GLOBAL SETTINGS'),
          _buildToggleCard(
            title: 'Quiet Hours',
            subtitle: 'Pause routine reminders during these hours',
            value: config.quietHoursEnabled,
            onChanged: (val) {
              ref
                  .read(remindersProvider.notifier)
                  .updateConfig(
                    ref
                        .read(remindersProvider)
                        .copyWith(quietHoursEnabled: val),
                  );
            },
            child: config.quietHoursEnabled
                ? Column(
                    children: [
                      _buildTimeSelector(
                        label: 'Start Time',
                        time: config.quietHoursStart,
                        onTap: () =>
                            _pickTime(context, config.quietHoursStart, (t) {
                              ref
                                  .read(remindersProvider.notifier)
                                  .updateConfig(
                                    ref
                                        .read(remindersProvider)
                                        .copyWith(quietHoursStart: t),
                                  );
                            }),
                      ),
                      const SizedBox(height: Spacing.stack),
                      _buildTimeSelector(
                        label: 'End Time',
                        time: config.quietHoursEnd,
                        onTap: () =>
                            _pickTime(context, config.quietHoursEnd, (t) {
                              ref
                                  .read(remindersProvider.notifier)
                                  .updateConfig(
                                    ref
                                        .read(remindersProvider)
                                        .copyWith(quietHoursEnd: t),
                                  );
                            }),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: Spacing.section),
          _buildSectionHeader('DAILY HABITS'),
          _buildToggleCard(
            title: 'Habit Reminder',
            subtitle: 'Remind me to log my habits',
            value: config.habitsEnabled,
            onChanged: (val) {
              ref
                  .read(remindersProvider.notifier)
                  .updateConfig(
                    ref.read(remindersProvider).copyWith(habitsEnabled: val),
                  );
            },
            child: config.habitsEnabled
                ? _buildTimeSelector(
                    label: 'Time',
                    time: config.habitTime,
                    previewText:
                        'Hey! Time to log your daily habits and keep your streak alive.',
                    onTap: () => _pickTime(context, config.habitTime, (t) {
                      ref
                          .read(remindersProvider.notifier)
                          .updateConfig(
                            ref.read(remindersProvider).copyWith(habitTime: t),
                          );
                    }),
                  )
                : null,
          ),
          const SizedBox(height: Spacing.section),
          _buildSectionHeader('WORKOUTS'),
          _buildToggleCard(
            title: 'Workout Reminder',
            subtitle: 'Remind me on scheduled workout days',
            value: config.workoutsEnabled,
            onChanged: (val) {
              ref
                  .read(remindersProvider.notifier)
                  .updateConfig(
                    ref.read(remindersProvider).copyWith(workoutsEnabled: val),
                  );
            },
            child: config.workoutsEnabled
                ? _buildTimeSelector(
                    label: 'Time',
                    time: config.workoutTime,
                    previewText:
                        'Time to crush today\'s workout! Are you ready?',
                    onTap: () => _pickTime(context, config.workoutTime, (t) {
                      ref
                          .read(remindersProvider.notifier)
                          .updateConfig(
                            ref
                                .read(remindersProvider)
                                .copyWith(workoutTime: t),
                          );
                    }),
                  )
                : null,
          ),
          const SizedBox(height: Spacing.section),
          _buildSectionHeader('MEALS'),
          _buildToggleCard(
            title: 'Meal Logging Nudge',
            subtitle: 'Remind me to track lunch and dinner',
            value: config.mealsEnabled,
            onChanged: (val) {
              ref
                  .read(remindersProvider.notifier)
                  .updateConfig(
                    ref.read(remindersProvider).copyWith(mealsEnabled: val),
                  );
            },
            child: config.mealsEnabled
                ? Column(
                    children: [
                      _buildTimeSelector(
                        label: 'Lunch Time',
                        time: config.lunchTime,
                        previewText:
                            'Time to log your lunch! Let\'s see what you had.',
                        onTap: () => _pickTime(context, config.lunchTime, (t) {
                          ref
                              .read(remindersProvider.notifier)
                              .updateConfig(
                                ref
                                    .read(remindersProvider)
                                    .copyWith(lunchTime: t),
                              );
                        }),
                      ),
                      const SizedBox(height: Spacing.stack),
                      _buildTimeSelector(
                        label: 'Dinner Time',
                        time: config.dinnerTime,
                        previewText: 'Don\'t forget to log your dinner!',
                        onTap: () => _pickTime(context, config.dinnerTime, (t) {
                          ref
                              .read(remindersProvider.notifier)
                              .updateConfig(
                                ref
                                    .read(remindersProvider)
                                    .copyWith(dinnerTime: t),
                              );
                        }),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: Spacing.section),
          _buildSectionHeader('DATA BACKUP'),
          _buildToggleCard(
            title: 'Weekly Backup Reminder',
            subtitle: 'Remind me to export my data securely',
            value: config.backupEnabled,
            onChanged: (val) {
              ref
                  .read(remindersProvider.notifier)
                  .updateConfig(
                    ref.read(remindersProvider).copyWith(backupEnabled: val),
                  );
            },
            child: config.backupEnabled
                ? Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Day of Week',
                            style: context.text.body.copyWith(
                              color: context.colors.textDark,
                            ),
                          ),
                          DropdownButton<int>(
                            isExpanded: true,
                            value: config.backupDayOfWeek,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: context.colors.primary,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: DateTime.monday,
                                child: Text('Monday'),
                              ),
                              const DropdownMenuItem(
                                value: DateTime.tuesday,
                                child: Text('Tuesday'),
                              ),
                              const DropdownMenuItem(
                                value: DateTime.wednesday,
                                child: Text('Wednesday'),
                              ),
                              const DropdownMenuItem(
                                value: DateTime.thursday,
                                child: Text('Thursday'),
                              ),
                              const DropdownMenuItem(
                                value: DateTime.friday,
                                child: Text('Friday'),
                              ),
                              const DropdownMenuItem(
                                value: DateTime.saturday,
                                child: Text('Saturday'),
                              ),
                              const DropdownMenuItem(
                                value: DateTime.sunday,
                                child: Text('Sunday'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(remindersProvider.notifier)
                                    .updateConfig(
                                      ref
                                          .read(remindersProvider)
                                          .copyWith(backupDayOfWeek: val),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.inline),
                      _buildTimeSelector(
                        label: 'Time',
                        time: config.backupTime,
                        previewText:
                            'Time for your weekly data backup. Keep your progress safe!',
                        onTap: () => _pickTime(context, config.backupTime, (t) {
                          ref
                              .read(remindersProvider.notifier)
                              .updateConfig(
                                ref
                                    .read(remindersProvider)
                                    .copyWith(backupTime: t),
                              );
                        }),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: Spacing.section),
          _buildSectionHeader('BODY COMPOSITION'),
          _buildToggleCard(
            title: 'Body Fat Reminder',
            subtitle: 'Weekly on Sunday at 10:00 AM',
            value: config.bodyFatEnabled,
            onChanged: (val) {
              ref
                  .read(remindersProvider.notifier)
                  .updateConfig(
                    ref.read(remindersProvider).copyWith(bodyFatEnabled: val),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: Spacing.inline,
        left: Spacing.textPair,
      ),
      child: Text(
        title,
        style: context.text.caption.copyWith(color: context.colors.primary),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        children: [
          MergeSemantics(
            child: SettingsRow(
              title: title,
              subtitle: subtitle,
              backgroundColor: Colors.transparent,
              showChevron: false,
              trailing: Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: context.colors.primary,
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.standard,
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: child != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: Spacing.cardPad,
                      right: Spacing.cardPad,
                      bottom: Spacing.cardPad,
                    ),
                    child: child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    String? previewText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    label,
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.stack,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Text(
                      _formatTime(time),
                      style: context.text.body.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (previewText != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 12,
                  color: context.colors.textLight,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '"$previewText"',
                  style: context.text.micro.copyWith(
                    color: context.colors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
