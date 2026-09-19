import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';

import '../../models/habit.dart';
import '../../utils/workout_completion.dart';
import '../../utils/workout_formatting.dart';
import '../../widgets/section_header.dart';
import '../../theme/layout_insets.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../providers/badge_engine_provider.dart';
import '../../widgets/surface_card.dart';
import '../profile/manage_habits_screen.dart';
import 'widgets/day_feeling_card.dart';
import 'widgets/week_calendar_strip.dart';
import 'widgets/meals_card.dart';
import 'widgets/home_greeting.dart';
import 'widgets/habits_card.dart';
import 'widgets/daily_progress_grid.dart';
import 'widgets/coach_notes_card.dart';
import 'widgets/daily_insight_card.dart';
import 'widgets/day_complete_sheet.dart';
import '../../theme/app_motion.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _habitsKey = GlobalKey();
  final _mealsKey = GlobalKey();
  final _progressKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initial sync when screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncControllerProvider.notifier).sync(isManualRefresh: false);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Removed _staggerWrap logic entirely to rely on a separate Stateful widget

  @override
  Widget build(BuildContext context) {
    ref.watch(badgeEngineProvider); // Initialize Gamification Engine
    final plan = ref.watch(workoutPlanProvider);
    ref.watch(syncControllerProvider);
    final hasInsight = ref.watch(insightsProvider).isNotEmpty;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.colors.scaffoldBg,
          body: RefreshIndicator(
            color: context.colors.primary,
            onRefresh: () => ref
                .read(syncControllerProvider.notifier)
                .sync(isManualRefresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.paddingOf(context).top + 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: kScreenPadding,
                        ),
                        child: StaggeredFadeIn(
                          key: ValueKey('home_greeting'),
                          index: 0,
                          child: HomeGreeting(),
                        ),
                      ),
                      const SizedBox(height: Spacing.section),

                      // 2. Week calendar + score
                      const StaggeredFadeIn(
                        key: ValueKey('calendar_strip'),
                        index: 1,
                        child: WeekCalendarStrip(),
                      ),
                      const DayCompleteAction(),
                      const SizedBox(height: Spacing.section),

                      // 3. Workout (primary daily action)
                      if (plan != null && plan.days.isNotEmpty) ...[
                        StaggeredFadeIn(
                          key: const ValueKey('workouts_section'),
                          index: 2,
                          child: _WorkoutsSection(plan: plan),
                        ),
                        const SizedBox(height: Spacing.section),
                      ],

                      // 4. Habits
                      StaggeredFadeIn(
                        key: const ValueKey('habits_section'),
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KeyedSubtree(
                              key: _habitsKey,
                              child: const SectionHeader(
                                'Habits',
                                trailing: _HabitsEditButton(),
                                countLabel: _HabitsCountLabel(),
                              ),
                            ),
                            const SizedBox(height: Spacing.stack),
                            const HabitsCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.section),

                      // 5. Meals
                      StaggeredFadeIn(
                        key: const ValueKey('meals_section'),
                        index: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KeyedSubtree(
                              key: _mealsKey,
                              child: const SectionHeader('Meals'),
                            ),
                            const SizedBox(height: Spacing.stack),
                            const MealsCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.section),

                      // 6. Daily progress metrics
                      StaggeredFadeIn(
                        key: const ValueKey('progress_section'),
                        index: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KeyedSubtree(
                              key: _progressKey,
                              child: const SectionHeader(
                                'Daily progress',
                                icon: Icons.show_chart_rounded,
                              ),
                            ),
                            const SizedBox(height: Spacing.stack),
                            const DailyProgressGrid(),
                            const SizedBox(height: Spacing.stack),
                            const _WeeklySummaryLink(),
                          ],
                        ),
                      ),

                      const SizedBox(height: Spacing.section),

                      // 7. Secondary Coach/Insight
                      if (hasInsight)
                        const StaggeredFadeIn(
                          key: ValueKey('insight_card'),
                          index: 6,
                          child: DailyInsightCard(),
                        )
                      else
                        const StaggeredFadeIn(
                          key: ValueKey('coach_notes_card'),
                          index: 6,
                          child: CoachNotesCard(),
                        ),

                      const SizedBox(height: Spacing.section),

                      // 8. Day Feeling Reflection
                      Consumer(
                        builder: (context, ref, _) {
                          final log = ref.watch(dailyLogProvider);
                          return StaggeredFadeIn(
                            key: const ValueKey('day_feeling_card'),
                            index: 7,
                            child: DayFeelingCard(
                              dateStr: log.date,
                              initialFeeling: log.dayFeeling,
                              initialNote: log.dayNote,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: shellScrollBottomPadding(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredFadeIn({super.key, required this.index, required this.child});

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  bool _played = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _played = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return _played
        ? widget.child
        : widget.child
              .animate(delay: (widget.index * 60).ms)
              .fadeIn(duration: Motion.deliberate, curve: Motion.enter)
              .slideY(
                begin: 0.08,
                end: 0,
                duration: Motion.deliberate,
                curve: Motion.enter,
              );
  }
}

class _WeeklySummaryLink extends StatelessWidget {
  const _WeeklySummaryLink();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () => context.push('/progress/weekly-summary'),
      margin: const EdgeInsets.symmetric(horizontal: Spacing.screen),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: context.colors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "This week's summary",
              style: context.text.body.copyWith(color: context.colors.textDark),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textLight,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _HabitsCountLabel extends ConsumerWidget {
  const _HabitsCountLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);
    final dailyLog = ref.watch(dailyLogProvider);
    final completedCount = habits
        .where((h) => isHabitCompleted(h, completions, dailyLog))
        .length;

    return Text(
      '$completedCount/${habits.length}',
      style: context.text.body.copyWith(color: context.colors.textLight),
    );
  }
}

class _HabitsEditButton extends StatelessWidget {
  const _HabitsEditButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Edit Habits',
      onPressed: () {
        Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute(builder: (_) => const ManageHabitsScreen()));
      },
      icon: Icon(Icons.edit_rounded, color: context.colors.primary),
    );
  }
}

class _WorkoutsSection extends ConsumerWidget {
  const _WorkoutsSection({required this.plan});

  final dynamic plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutPlan = ref.watch(workoutPlanProvider);
    final phaseProgress = ref.watch(phaseProgressProvider);
    if (workoutPlan == null || !WorkoutCompletion.hasSchedule(workoutPlan)) {
      return const SizedBox();
    }

    final dateStr = ref.watch(dateStringProvider);

    final selectedDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = selectedDate.isAfter(today);

    final day = WorkoutCompletion.resolveWorkoutDay(
      workoutPlan,
      selectedDate,
      planStartDate: ref.watch(profileProvider).planStartDate,
    );
    final isRest = WorkoutCompletion.isRestDay(day, selectedDate);

    final logRepo = ref.watch(exerciseLogRepoProvider);
    ref.watch(exerciseLogsUpdateProvider); // Rebuild when logs are saved
    ref.watch(exerciseRecordsUpdateProvider);
    final dailyLog = ref.watch(dailyLogProvider);
    final isWholeDayCompleted = WorkoutCompletion.isDayWorkoutDoneWithRepo(
      date: dateStr,
      day: day,
      dateTime: selectedDate,
      repo: logRepo,
      dailyLog: dailyLog,
    );

    final List<Widget> cards = [];
    int completedCount = 0;

    if (isRest) {
      cards.add(
        _buildCard(
          context,
          title: 'Rest Day',
          subtitle: 'Recovery day — you\'re all set. Rest counts as complete.',
          isCompleted: isWholeDayCompleted,
          isFuture: isFuture,
          isRest: true,
        ),
      );
      if (isWholeDayCompleted) completedCount = 1;
    } else {
      for (int i = 0; i < day.sections.length; i++) {
        if (i > 0) cards.add(const SizedBox(height: Spacing.stack));
        final sec = day.sections[i];

        final isCompleted = WorkoutCompletion.isSectionCompleteWithRepo(
          dateStr,
          sec,
          logRepo,
        );
        if (isCompleted) completedCount++;

        final String title = formatSectionTitle(sec.title, i);

        int exercisesLogged = 0;
        int firstUnloggedIndex = -1;
        String? firstUnlogged;
        for (int e = 0; e < sec.exercises.length; e++) {
          final ex = sec.exercises[e];
          if (logRepo.hasLog(dateStr, ex.instanceId ?? '')) {
            exercisesLogged++;
          } else if (firstUnlogged == null) {
            firstUnlogged = ex.name;
            firstUnloggedIndex = e;
          }
        }

        String subtitle;
        if (exercisesLogged == 0) {
          subtitle = '${sec.exercises.length} exercises · Ready to start';
        } else if (exercisesLogged == sec.exercises.length) {
          subtitle =
              '${sec.exercises.length}/${sec.exercises.length} logged · View workout';
        } else {
          subtitle =
              'Continue · $exercisesLogged/${sec.exercises.length} logged · Next: $firstUnlogged';
        }

        cards.add(
          _buildCard(
            context,
            title: title,
            subtitle: subtitle,
            isCompleted: isCompleted,
            isFuture: isFuture,
            isRest: false,
            heroTag: 'workout-${day.dayId}-section-$i',
            onTap: () {
              String route =
                  '/home/workout/${Uri.encodeComponent(day.dayId ?? '')}?section=$i';
              if (firstUnloggedIndex != -1 && exercisesLogged > 0) {
                route += '&jumpTo=$firstUnloggedIndex';
              }
              context.go(route);
            },
          ),
        );
      }
    }

    final total = isRest ? 1 : day.sections.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Workouts',
          countLabel: Text(
            '($completedCount/$total)',
            style: context.text.body.copyWith(
              color: context.colors.primary.withValues(alpha: 0.8),
            ),
          ),
          trailing: phaseProgress.isPhaseActive
              ? Row(
                  children: [
                    Text(
                      'Week ${phaseProgress.currentWeek} of ${phaseProgress.totalWeeks}',
                      style: context.text.micro.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value:
                            (phaseProgress.currentWeek /
                                    phaseProgress.totalWeeks)
                                .clamp(0.0, 1.0),
                        strokeWidth: 2,
                        backgroundColor: context.colors.primary.withValues(
                          alpha: 0.2,
                        ),
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                )
              : null,
        ),
        const SizedBox(height: Spacing.stack),
        if (phaseProgress.isPhaseComplete)
          Container(
            margin: const EdgeInsets.only(
              bottom: Spacing.stack,
              left: Spacing.screen,
              right: Spacing.screen,
            ),
            padding: const EdgeInsets.all(Spacing.major),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(Radii.card),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your ${phaseProgress.totalWeeks}-week plan has reached the end.",
                  style: context.text.cardTitle.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
                const SizedBox(height: Spacing.stack),
                Text(
                  "Review your progress, then repeat this plan or choose what comes next.",
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
                const SizedBox(height: Spacing.block),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.primary,
                          side: BorderSide(
                            color: context.colors.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        onPressed: () {
                          final profile = ref.read(profileProvider);
                          ref
                              .read(profileProvider.notifier)
                              .updateProfile(
                                profile.copyWith(planStartDate: DateTime.now()),
                              );
                        },
                        child: const Text('Repeat Plan'),
                      ),
                    ),
                    const SizedBox(width: Spacing.stack),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primaryDark,
                          foregroundColor: context.colors.white,
                        ),
                        onPressed: () {
                          context.push('/profile/manage-plans');
                        },
                        child: const Text('Start New'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Column(children: cards),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isFuture,
    required bool isRest,
    String? heroTag,
    VoidCallback? onTap,
  }) {
    return SurfaceCard(
      onTap: isFuture ? null : onTap,
      margin: const EdgeInsets.symmetric(horizontal: Spacing.screen),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.cardPad,
        vertical: Spacing.cardPadTight,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heroTag != null)
                  Hero(
                    tag: heroTag,
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        title,
                        style: context.text.cardTitle.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    title,
                    style: context.text.cardTitle.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                const SizedBox(height: Gap.x4),
                Text(
                  subtitle,
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: context.colors.green),
            )
          else if (isRest)
            Icon(
              Icons.self_improvement_rounded,
              color: context.colors.textMedium,
              size: 32,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textMedium,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
