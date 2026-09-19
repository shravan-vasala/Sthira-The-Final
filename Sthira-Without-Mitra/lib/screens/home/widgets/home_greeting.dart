import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/profile_avatar.dart';

import '../../../providers/app_providers.dart';
import '../../../providers/midnight_tick_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Keeps the greeting current at the next day-part boundary and on app resume.
class HomeGreeting extends ConsumerStatefulWidget {
  const HomeGreeting({super.key, this.clock});

  /// Uses the device clock by default; injectable for deterministic previews/tests.
  final DateTime Function()? clock;

  @override
  ConsumerState<HomeGreeting> createState() => _HomeGreetingState();
}

class _HomeGreetingState extends ConsumerState<HomeGreeting>
    with WidgetsBindingObserver {
  late DateTime _now;
  Timer? _boundaryTimer;

  DateTime _readClock() => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = _readClock();
    _scheduleBoundary();
  }

  @override
  void didUpdateWidget(HomeGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clock != widget.clock) {
      _now = _readClock();
      _scheduleBoundary();
    }
  }

  void _scheduleBoundary() {
    _boundaryTimer?.cancel();
    final nextBoundary = _now.hour < 12
        ? DateTime(_now.year, _now.month, _now.day, 12)
        : _now.hour < 17
        ? DateTime(_now.year, _now.month, _now.day, 17)
        : DateTime(_now.year, _now.month, _now.day + 1);
    _boundaryTimer = Timer(nextBoundary.difference(_now), _refreshTime);
  }

  void _refreshTime() {
    if (!mounted) return;
    setState(() => _now = _readClock());
    _scheduleBoundary();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTime();
    } else {
      _boundaryTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _boundaryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Preserve the app's existing midnight date rollover activation.
    ref.watch(midnightTickProvider);
    final profile = ref.watch(
      profileProvider.select((profile) => (profile.name, profile.photoPath)),
    );
    final selectedDate = ref.watch(selectedDateProvider);

    return HomeGreetingContent(
      name: profile.$1,
      profileAction: _HomeProfileAction(
        name: profile.$1,
        photoPath: profile.$2,
      ),
      selectedDate: selectedDate,
      now: _now,
      onReturnToToday: () {
        final now = _readClock();
        ref.read(selectedDateProvider.notifier).state = DateTime(
          now.year,
          now.month,
          now.day,
        );
        ref.read(weekOffsetProvider.notifier).state = 0;
      },
    );
  }
}

/// Presentation of the current day context, independent of data and timers.
class HomeGreetingContent extends StatelessWidget {
  const HomeGreetingContent({
    super.key,
    required this.name,
    required this.selectedDate,
    required this.now,
    required this.onReturnToToday,
    this.profileAction,
  });

  final String name;
  final DateTime selectedDate;
  final DateTime now;
  final VoidCallback onReturnToToday;
  final Widget? profileAction;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isToday = selectedDay == today;
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final trimmedName = name.trim();
    final dateFormat = selectedDate.year == now.year
        ? 'EEEE, d MMMM'
        : 'EEEE, d MMMM yyyy';
    final dayContext = isToday
        ? 'today'
        : selectedDay.isBefore(today)
        ? 'past day'
        : 'future day';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                DateFormat(dateFormat).format(selectedDate),
                semanticsLabel:
                    'Selected day: ${DateFormat('EEEE, d MMMM yyyy').format(selectedDay)}, $dayContext',
                style: context.text.caption.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),
            if (profileAction != null) ...[
              const SizedBox(width: Spacing.inline),
              profileAction!,
            ],
          ],
        ),
        const SizedBox(height: Spacing.textPair),
        Semantics(
          header: true,
          child: isToday
              ? Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: trimmedName.isEmpty ? greeting : '$greeting, ',
                        style: context.text.screenTitle.copyWith(
                          color: context.colors.textMedium,
                        ),
                      ),
                      if (trimmedName.isNotEmpty)
                        TextSpan(
                          text: trimmedName,
                          style: context.text.screenTitle.copyWith(
                            color: context.colors.textDark,
                          ),
                        ),
                    ],
                  ),
                )
              : Text(
                  selectedDay.isBefore(today)
                      ? 'Your day in review'
                      : 'Your day ahead',
                  style: context.text.screenTitle,
                ),
        ),
        if (!isToday) ...[
          const SizedBox(height: Spacing.inline),
          TextButton.icon(
            onPressed: onReturnToToday,
            icon: const Icon(
              Icons.calendar_today_rounded,
              size: IconSize.inline,
            ),
            label: const Text('Return to today'),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: context.colors.accentText,
              backgroundColor: context.colors.primary.withValues(alpha: 0.1),
              textStyle: context.text.caption,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.stack),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeProfileAction extends StatelessWidget {
  const _HomeProfileAction({required this.name, required this.photoPath});
  final String name;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open profile',
      excludeFromSemantics: true,
      child: IconButton(
        key: const ValueKey('home-profile-action'),
        onPressed: () => context.go('/profile'),
        padding: const EdgeInsets.all(2),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Semantics(
          label: 'Open profile',
          child: Container(
            width: 44,
            height: 44,
            foregroundDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.border, width: 1),
            ),
            child: ProfileAvatar(name: name, photoPath: photoPath),
          ),
        ),
      ),
    );
  }
}
