class SocialProfile {
  final String uid;
  final String name;
  final String? avatarUrl;
  final int todaySteps;
  final int todayWorkouts;
  final int currentStreak;
  final int weeklySteps;
  final int weeklyWorkouts;
  final String? latestBadge;
  final DateTime lastUpdatedAt;
  final List<String>? allowedReaders;
  final int? todayScore;
  final int? weekScore;
  final String? statsDate;
  final String? weekStartDate;
  final bool? hasStepsRecord;
  final int? weeklyStepsRecordedDays;
  final int? weekScoreRecordedDays;
  final bool todayWorkoutsKnown;
  final bool weeklyWorkoutsKnown;
  final bool streakKnown;

  SocialProfile({
    required this.uid,
    required this.name,
    this.avatarUrl,
    required this.todaySteps,
    required this.todayWorkouts,
    required this.currentStreak,
    required this.weeklySteps,
    required this.weeklyWorkouts,
    this.latestBadge,
    required this.lastUpdatedAt,
    this.allowedReaders,
    this.todayScore,
    this.weekScore,
    this.statsDate,
    this.weekStartDate,
    this.hasStepsRecord,
    this.weeklyStepsRecordedDays,
    this.weekScoreRecordedDays,
    this.todayWorkoutsKnown = true,
    this.weeklyWorkoutsKnown = true,
    this.streakKnown = true,
  });

  bool get hasValidSharedTimestamp => lastUpdatedAt.millisecondsSinceEpoch > 0;

  /// Dates describe the sender's logged calendar day, not the network arrival day.
  DateTime? get statsDay => statsDate != null
      ? _parseDay(statsDate)
      : hasValidSharedTimestamp
      ? _day(lastUpdatedAt.toLocal())
      : null;

  DateTime? get sharedWeekStart {
    if (weekStartDate != null) {
      final start = _parseDay(weekStartDate);
      return start?.weekday == DateTime.monday ? start : null;
    }
    final date = statsDay;
    return date == null ? null : _monday(date);
  }

  bool isCurrentDay(DateTime now) => statsDay == _day(now.toLocal());

  bool isCurrentWeek(DateTime now) {
    final today = _day(now.toLocal());
    final recordedDay = statsDay;
    return sharedWeekStart == _monday(today) &&
        recordedDay != null &&
        !recordedDay.isAfter(today);
  }

  bool get hasKnownTodaySteps =>
      todaySteps >= 0 && (hasStepsRecord ?? todaySteps > 0);
  bool get hasKnownWeeklySteps =>
      weeklySteps >= 0 &&
      (weeklyStepsRecordedDays != null
          ? weeklyStepsRecordedDays! > 0
          : weeklySteps > 0);
  bool get hasKnownWeekScore =>
      weekScore != null &&
      weekScore! >= 0 &&
      weekScore! <= 100 &&
      weekStartDate != null &&
      sharedWeekStart != null &&
      (weekScoreRecordedDays ?? 0) > 0;
  int? get todayWorkoutsValue =>
      todayWorkoutsKnown && todayWorkouts >= 0 ? todayWorkouts : null;
  int? get weeklyWorkoutsValue =>
      weeklyWorkoutsKnown && weeklyWorkouts >= 0 ? weeklyWorkouts : null;
  int? get currentStreakValue =>
      streakKnown && currentStreak >= 0 ? currentStreak : null;

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    final steps = _integer(json['todaySteps']);
    final weeklySteps = _integer(json['weeklySteps']);
    final workouts = _integer(json['todayWorkouts']);
    final weeklyWorkouts = _integer(json['weeklyWorkouts']);
    final streak = _integer(json['currentStreak']);
    final timestamp = _integer(json['lastUpdatedAt']);
    DateTime sharedAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (timestamp != null && timestamp > 0 && timestamp <= 8640000000000000) {
      sharedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return SocialProfile(
      uid: json['uid'] is String ? json['uid'] as String : '',
      name: json['name'] is String ? json['name'] as String : 'Unknown',
      avatarUrl: json['avatarUrl'] is String
          ? json['avatarUrl'] as String
          : null,
      todaySteps: steps ?? 0,
      todayWorkouts: workouts ?? 0,
      currentStreak: streak ?? 0,
      weeklySteps: weeklySteps ?? 0,
      weeklyWorkouts: weeklyWorkouts ?? 0,
      latestBadge: json['latestBadge'] is String
          ? json['latestBadge'] as String
          : null,
      lastUpdatedAt: sharedAt,
      allowedReaders: json['allowedReaders'] is List
          ? (json['allowedReaders'] as List).whereType<String>().toList()
          : null,
      todayScore: _integer(json['todayScore'], maximum: 100),
      weekScore: _integer(json['weekScore'], maximum: 100),
      statsDate: json['statsDate'] is String
          ? json['statsDate'] as String
          : null,
      weekStartDate: json['weekStartDate'] is String
          ? json['weekStartDate'] as String
          : null,
      hasStepsRecord: steps == null
          ? false
          : json['hasStepsRecord'] is bool
          ? json['hasStepsRecord'] as bool
          : null,
      weeklyStepsRecordedDays: weeklySteps == null
          ? 0
          : _integer(json['weeklyStepsRecordedDays'], maximum: 7),
      weekScoreRecordedDays: _integer(
        json['weekScoreRecordedDays'],
        maximum: 7,
      ),
      todayWorkoutsKnown: workouts != null,
      weeklyWorkoutsKnown: weeklyWorkouts != null,
      streakKnown: streak != null,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'avatarUrl': avatarUrl,
    'todaySteps': todaySteps,
    if (todayWorkoutsKnown) 'todayWorkouts': todayWorkouts,
    if (streakKnown) 'currentStreak': currentStreak,
    'weeklySteps': weeklySteps,
    if (weeklyWorkoutsKnown) 'weeklyWorkouts': weeklyWorkouts,
    'latestBadge': latestBadge,
    'lastUpdatedAt': lastUpdatedAt.millisecondsSinceEpoch,
    if (allowedReaders != null) 'allowedReaders': allowedReaders,
    'todayScore': todayScore,
    'weekScore': weekScore,
    'statsDate': statsDate,
    'weekStartDate': weekStartDate,
    'hasStepsRecord': hasStepsRecord,
    'weeklyStepsRecordedDays': weeklyStepsRecordedDays,
    'weekScoreRecordedDays': weekScoreRecordedDays,
  };
}

int? _integer(dynamic value, {int? maximum}) {
  if (value is! num ||
      !value.isFinite ||
      value < 0 ||
      value > 9007199254740991 ||
      value != value.roundToDouble()) {
    return null;
  }
  if (maximum != null && value > maximum) return null;
  return value.toInt();
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime _monday(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1 - date.weekday);
DateTime? _parseDay(String? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  final key =
      '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  return key == value ? _day(parsed) : null;
}
