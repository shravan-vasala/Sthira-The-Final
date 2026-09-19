import 'dart:async';
import 'providers/notification_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'repositories/workout_repository.dart';
import 'repositories/meal_repository.dart';
import 'repositories/daily_log_repository.dart';
import 'repositories/habit_repository.dart';
import 'repositories/body_stats_repository.dart';
import 'repositories/media_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/exercise_log_repository.dart';
import 'repositories/badge_repository.dart';
import 'repositories/coach_note_repository.dart';
import 'repositories/friend_repository.dart';
import 'repositories/photo_meal_repository.dart';
import 'services/health_connect_service.dart';
import 'services/notification_service.dart';
import 'services/schema_migration_service.dart';
import 'providers/app_providers.dart';
import 'providers/reminders_provider.dart';
import 'services/diagnostic_logger.dart';
import 'router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_sync_service.dart';
import 'services/app_database_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models
import 'services/ai_cache.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Lock to portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    final authService = AuthService();
    final isar = await AppDatabaseManager.openDatabaseForUser(authService.uid);

    await SchemaMigrationService.runStartupMigrations(isar);

    // Initialize all repositories
    final workoutRepo = WorkoutRepository();
    final mealRepo = MealRepository();
    final photoMealRepo = PhotoMealRepository();
    final dailyLogRepo = DailyLogRepository();
    final habitRepo = HabitRepository();
    final bodyStatsRepo = BodyStatsRepository();
    final mediaRepo = MediaRepository();
    final profileRepo = ProfileRepository();
    final exerciseLogRepo = ExerciseLogRepository();
    final coachNoteRepo = CoachNoteRepository();
    final badgeRepo = BadgeRepository();
    final friendRepo = FriendRepository(isar);
    final healthConnectService = HealthConnectService();

    await Future.wait([
      workoutRepo.init(isar),
      mealRepo.init(isar),
      photoMealRepo.init(isar),
      dailyLogRepo.init(isar),
      habitRepo.init(isar),
      bodyStatsRepo.init(isar),
      mediaRepo.init(isar),
      profileRepo.init(isar),
      exerciseLogRepo.init(isar),
      coachNoteRepo.init(isar),
      badgeRepo.init(isar),
      healthConnectService.init(isar),
      NotificationService().init(),
    ]);

    final firestoreSyncService = FirestoreSyncService(
      authService,
      databaseResolver: () => profileRepo.isar,
      startPaused: true,
    );

    final prefs = await SharedPreferences.getInstance();
    final logger = DiagnosticLogger(prefs);
    logger.info('Sthira started cleanly');

    runApp(
      ProviderScope(
        observers: [DiagnosticProviderObserver(logger)],
        overrides: [
          workoutRepoProvider.overrideWithValue(workoutRepo),
          mealRepoProvider.overrideWithValue(mealRepo),
          photoMealRepoProvider.overrideWithValue(photoMealRepo),
          dailyLogRepoProvider.overrideWithValue(dailyLogRepo),
          habitRepoProvider.overrideWithValue(habitRepo),
          bodyStatsRepoProvider.overrideWithValue(bodyStatsRepo),
          mediaRepoProvider.overrideWithValue(mediaRepo),
          profileRepoProvider.overrideWithValue(profileRepo),
          exerciseLogRepoProvider.overrideWithValue(exerciseLogRepo),
          coachNoteRepoProvider.overrideWithValue(coachNoteRepo),
          badgeRepoProvider.overrideWithValue(badgeRepo),
          friendRepoProvider.overrideWithValue(friendRepo),
          healthConnectServiceProvider.overrideWithValue(healthConnectService),
          authServiceProvider.overrideWithValue(authService),
          firestoreSyncServiceProvider.overrideWithValue(firestoreSyncService),
          sharedPreferencesProvider.overrideWithValue(prefs),
          diagnosticLoggerProvider.overrideWith((ref) => logger),
        ],
        child: const TruFitApp(),
      ),
    );

    // Unawaited routine background cache pruning uncoupled from strict schema migrations safely
    // ignore: unawaited_futures
    AiCache(databaseResolver: () => profileRepo.isar).prune();
  } catch (e, stack) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/crash_log.txt');
      await logFile.writeAsString('Error:\n$e\n\nStack:\n$stack');

      runApp(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Fatal Error on Startup.\n\nA crash log has been saved to:\n${logFile.path}\n\nError: $e',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (fallbackErr) {
      runApp(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Fatal Error on Startup:\n\n$e',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

class TruFitApp extends ConsumerStatefulWidget {
  const TruFitApp({super.key});

  @override
  ConsumerState<TruFitApp> createState() => _TruFitAppState();
}

class _TruFitAppState extends ConsumerState<TruFitApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize notifications and sync them
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(accountSessionProvider).start();
      ref.read(notificationActionControllerProvider);
      ref.read(backupServiceProvider).autoBackup();
      ref.read(remindersProvider.notifier).initializeNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final social = ref.read(socialSyncServiceProvider);
    if (social.canSync)
      unawaited(social.flushProfile().catchError((Object _) {}));
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref
            .read(accountSessionProvider)
            .ensureActive()
            .catchError((Object _) {}),
      );
      unawaited(ref.read(socialRelationshipProvider)?.refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(reminderNavigationProvider, (previous, next) {
      if (next == null) return;
      ref.read(selectedDateProvider.notifier).state = next.date;
      final workoutDay = ref.read(resolvedWorkoutDayProvider(next.date));
      final path = switch (next.type) {
        'lunch' || 'dinner' => '/home/meals',
        'backup' => '/profile/backup-restore',
        'photo' => '/home/physique-pictures',
        'bodyFat' => '/home/body-stats',
        'workout' =>
          workoutDay?.dayId == null
              ? '/home'
              : '/home/workout/${Uri.encodeComponent(workoutDay!.dayId!)}',
        _ => '/home',
      };
      ref.read(appRouterProvider).go(path);
      ref.read(reminderNavigationProvider.notifier).state = null;
    });
    ref.watch(socialPushControllerProvider);
    ref.watch(widgetCoordinatorProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Sthira',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AppErrorFeedback(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              (Theme.of(context).brightness == Brightness.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Theme.of(
                      context,
                    ).scaffoldBackgroundColor,
                  ),
          child: Stack(
            children: [
              if (child != null) child,
              if (ref.watch(accountTransitionProvider))
                Positioned.fill(
                  child: Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(
                              ref.watch(accountSessionErrorProvider) ??
                                  'Preparing your account…',
                              textAlign: TextAlign.center,
                            ),
                            if (ref.watch(accountSessionErrorProvider) != null)
                              TextButton(
                                onPressed: () => unawaited(
                                  ref
                                      .read(accountSessionProvider)
                                      .refresh()
                                      .catchError((Object _) {}),
                                ),
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps global errors inside the current account's ScaffoldMessenger lifecycle.
/// Normal messages join the existing queue so an Undo or Retry stays usable.
class AppErrorFeedback extends ConsumerStatefulWidget {
  const AppErrorFeedback({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppErrorFeedback> createState() => _AppErrorFeedbackState();
}

class _AppErrorFeedbackState extends ConsumerState<AppErrorFeedback> {
  final Map<(String, bool), VoidCallback> _pendingErrors = {};
  bool _clearPending = false;
  bool _scheduled = false;

  void _scheduleFeedback() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final pending = _pendingErrors.values.toList();
      _pendingErrors.clear();
      if (_clearPending) {
        _clearPending = false;
        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      }
      for (final show in pending) {
        show();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _clearPreviousMessages() {
    _clearPending = true;
    _scheduleFeedback();
  }

  void _showError(String? message, {bool accountError = false}) {
    if (message == null || message.trim().isEmpty) return;
    final generation = ref.read(accountGenerationProvider);
    final account = ref.read(activeAccountIdProvider);
    // Repeated reports in one frame share a single queue entry.
    _pendingErrors[(message, accountError)] = () {
      if (!mounted || ref.read(accountTransitionProvider)) return;
      // Refresh advances the generation when it finishes, even when the bound
      // account is unchanged. Keep that account's current failure recoverable.
      if (accountError) {
        if (ref.read(accountHydratingProvider)) return;
        if (account != ref.read(activeAccountIdProvider) ||
            message != ref.read(accountSessionErrorProvider)) {
          return;
        }
      } else if (generation != ref.read(accountGenerationProvider)) {
        return;
      }
      final actionGeneration = ref.read(accountGenerationProvider);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message),
          action: accountError
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    if (!mounted ||
                        actionGeneration !=
                            ref.read(accountGenerationProvider) ||
                        ref.read(accountTransitionProvider)) {
                      return;
                    }
                    unawaited(
                      ref
                          .read(accountSessionProvider)
                          .refresh()
                          .catchError((Object _) {}),
                    );
                  },
                )
              : null,
        ),
      );
    };
    _scheduleFeedback();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountGenerationProvider, (previous, next) {
      if (previous != next) _clearPreviousMessages();
    });
    ref.listen(accountTransitionProvider, (previous, next) {
      if (next) {
        _clearPreviousMessages();
      } else if (previous == true) {
        // The blocking account screen already owns Retry while it is visible.
        _showError(ref.read(accountSessionErrorProvider), accountError: true);
      }
    });
    ref.listen(accountHydratingProvider, (previous, next) {
      if (previous == true && !next) {
        _showError(ref.read(accountSessionErrorProvider), accountError: true);
      }
    });
    ref.listen(reminderErrorProvider, (previous, next) {
      if (!ref.read(accountTransitionProvider)) _showError(next);
    });
    ref.listen(socialErrorProvider, (previous, next) {
      if (!ref.read(accountTransitionProvider)) _showError(next);
    });
    ref.listen(accountSessionErrorProvider, (previous, next) {
      if (!ref.read(accountTransitionProvider)) {
        _showError(next, accountError: true);
      }
    });
    return widget.child;
  }
}
