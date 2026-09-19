import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/widget_open_screen.dart';
import '../utils/widget_navigation.dart';
import '../screens/home/meal_detail_screen.dart';
import '../screens/home/body_stats_screen.dart';
import '../screens/home/physique_pictures_screen.dart';
import '../screens/workout/workout_screen.dart';
import '../screens/workout/youtube_player_screen.dart';
import '../screens/workout/exercise_progress_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/progress/weekly_summary_screen.dart';
import '../screens/progress/yearly_activity_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/manage_plans_screen.dart';
import '../screens/profile/backup_restore_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/reminders_screen.dart';
import '../theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/badge_overlay_host.dart';
import '../screens/social/social_feed_screen.dart';
import '../screens/social/connect_screen.dart';
import '../services/haptics.dart';
import '../widgets/rest_timer_bar.dart';
import '../widgets/app_navigation_bar.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _progressNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'progress');
final _socialNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'social');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(onboardingCompletedProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final appRouterProvider = Provider<GoRouter>((ref) {
  // ignore: unused_local_variable
  final prefs = ref.watch(sharedPreferencesProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: ref.watch(routerNotifierProvider),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'This page doesn\'t exist or was removed.',
                style: context.text.bodyStrong.copyWith(
                  color: context.colors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final isCompleted = ref.read(onboardingCompletedProvider);

      if (!isCompleted && state.uri.path != '/onboarding') {
        return '/onboarding';
      }

      if (isCompleted && state.uri.path == '/onboarding') {
        return '/home';
      }

      final widgetLocation = normalizeWidgetLocation(state.uri);
      if (widgetLocation != null && widgetLocation != state.uri.toString()) {
        return widgetLocation;
      }
      if (state.uri.path == '/' || state.uri.path.isEmpty) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/widget/:action',
        builder: (context, state) =>
            WidgetOpenScreen(action: state.pathParameters['action']!),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'meals',
                    builder: (context, state) => const MealDetailScreen(),
                  ),
                  GoRoute(
                    path: 'body-stats',
                    builder: (context, state) => const BodyStatsScreen(),
                  ),
                  GoRoute(
                    path: 'physique-pictures',
                    builder: (context, state) => const PhysiquePicturesScreen(),
                  ),
                  GoRoute(
                    path: 'workout/:dayId',
                    builder: (context, state) {
                      final dayId = state.pathParameters['dayId']!;
                      final sectionParam = state.uri.queryParameters['section'];
                      final sectionIndex = sectionParam != null
                          ? int.tryParse(sectionParam)
                          : null;
                      final jumpToParam = state.uri.queryParameters['jumpTo'];
                      final jumpToIndex = jumpToParam != null
                          ? int.tryParse(jumpToParam)
                          : null;
                      return WorkoutScreen(
                        dayId: dayId,
                        sectionIndex: sectionIndex,
                        jumpToIndex: jumpToIndex,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _progressNavigatorKey,
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) {
                  final metricStr = state.uri.queryParameters['metric'];
                  MetricType? metric;
                  if (metricStr != null) {
                    switch (metricStr) {
                      case 'weight':
                        metric = MetricType.weight;
                        break;
                      case 'steps':
                        metric = MetricType.steps;
                        break;
                      case 'sleep':
                        metric = MetricType.sleep;
                        break;
                      case 'bmi':
                        metric = MetricType.bmi;
                        break;
                      case 'bodyFat':
                        metric = MetricType.bodyFat;
                        break;
                      case 'calories':
                        metric = MetricType.calories;
                        break;
                      case 'protein':
                      case 'macros': // legacy deep link
                        metric = MetricType.protein;
                        break;
                    }
                  }
                  return ProgressScreen(initialMetric: metric);
                },
                routes: [
                  GoRoute(
                    path: 'weekly-summary',
                    builder: (context, state) => const WeeklySummaryScreen(),
                  ),
                  GoRoute(
                    path: 'yearly-activity',
                    builder: (context, state) => const YearlyActivityScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _socialNavigatorKey,
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const SocialFeedScreen(),
                routes: [
                  GoRoute(
                    path: 'connect',
                    builder: (context, state) => const ConnectScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'manage-plans',
                    builder: (context, state) => const ManagePlansScreen(),
                  ),
                  GoRoute(
                    path: 'backup-restore',
                    builder: (context, state) => const BackupRestoreScreen(),
                  ),
                  GoRoute(
                    path: 'reminders',
                    builder: (context, state) => const RemindersScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen routes (outside bottom nav)
      GoRoute(
        path: '/youtube-player',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final videoId = state.uri.queryParameters['videoId'] ?? '';
          final title = state.uri.queryParameters['title'] ?? '';
          final subtitle = state.uri.queryParameters['subtitle'] ?? '';
          final reps = state.uri.queryParameters['reps'] ?? '';
          return YoutubePlayerScreen(
            videoId: videoId,
            title: title,
            subtitle: subtitle,
            reps: reps,
          );
        },
      ),
      GoRoute(
        path: '/exercise-progress',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final exerciseName = state.uri.queryParameters['name'] ?? '';
          return ExerciseProgressScreen(exerciseName: exerciseName);
        },
      ),
    ],
  );
});

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerActive = ref.watch(
      restTimerProvider.select((state) => state.isActive),
    );
    final canPopInner = GoRouter.of(context).canPop();
    final isHomeTab = navigationShell.currentIndex == 0;

    return PopScope(
      canPop: isHomeTab && !canPopInner,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (canPopInner) {
          GoRouter.of(context).pop();
        } else if (!isHomeTab) {
          navigationShell.goBranch(0, initialLocation: false);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            extendBody: true,
            body: navigationShell,
            bottomNavigationBar: AppNavigationDock(
              currentIndex: navigationShell.currentIndex,
              onItemSelected: (index) {
                Haptics.tap();
                navigationShell.goBranch(index);
              },
              restTimer: timerActive
                  ? Consumer(
                      builder: (context, ref, child) {
                        final timerState = ref.watch(restTimerProvider);
                        return RestTimerBar(
                          remainingSeconds: timerState.remainingSeconds,
                          isPaused: timerState.isPaused,
                          exerciseName: timerState.exerciseName,
                          onAddSeconds: (seconds) => ref
                              .read(restTimerProvider.notifier)
                              .addSeconds(seconds),
                          onTogglePause: () {
                            final timer = ref.read(restTimerProvider.notifier);
                            if (timerState.isPaused) {
                              timer.resumeTimer();
                            } else {
                              timer.pauseTimer();
                            }
                          },
                          onClose: () =>
                              ref.read(restTimerProvider.notifier).stopTimer(),
                        );
                      },
                    )
                  : null,
            ),
          ),

          const BadgeOverlayHost(),
        ],
      ),
    );
  }
}
