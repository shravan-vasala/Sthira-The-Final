import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';

final midnightTickProvider = NotifierProvider<MidnightTickNotifier, void>(
  MidnightTickNotifier.new,
);

class MidnightTickNotifier extends Notifier<void> {
  Timer? _timer;
  late DateTime _lastDay;
  @override
  void build() {
    final now = DateTime.now();
    _lastDay = DateTime(now.year, now.month, now.day);
    _schedule();
    ref.onDispose(() => _timer?.cancel());
  }

  void refresh() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = ref.read(selectedDateProvider);
    if (today != _lastDay && selected == _lastDay) {
      ref.read(selectedDateProvider.notifier).state = today;
    }
    _lastDay = today;
    ref.invalidate(clockProvider);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(
      next.difference(now) + const Duration(milliseconds: 100),
      refresh,
    );
  }
}
