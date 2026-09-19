import 'package:intl/intl.dart';

/// One shared `todayKey()` util for the `yyyy-MM-dd` local-date keying.
/// This prevents fragmented timezone bugs across screens and sets the bedrock for Midnight rollover fixes.
String todayKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  return DateFormat('yyyy-MM-dd').format(d);
}

/// Normalizes any DateTime strictly to midnight (00:00:00.000) of its local calendar day.
DateTime startOfDay([DateTime? date]) {
  final d = date ?? DateTime.now();
  return DateTime(d.year, d.month, d.day);
}

/// Provides a robust Monday-anchored start of week.
/// In Dart, DateTime.monday == 1 ... DateTime.sunday == 7.
DateTime weekStartOf([DateTime? date]) {
  final d = startOfDay(date);
  final daysToSubtract = d.weekday - DateTime.monday;
  return d.subtract(Duration(days: daysToSubtract));
}
