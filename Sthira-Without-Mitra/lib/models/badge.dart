import 'package:isar/isar.dart';

part 'badge.g.dart';

@collection
class Badge {
  Id idInternal = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;
  final String category; // 'workout', 'streak', 'habit', 'meal'
  final String title;
  final String description;
  final String iconEmoji;
  final int requiredProgress;
  final int currentProgress;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  Badge({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.requiredProgress,
    this.currentProgress = 0,
    this.unlockedAt,
  });

  Badge copyWith({int? currentProgress, DateTime? unlockedAt}) {
    return Badge(
      id: id,
      category: category,
      title: title,
      description: description,
      iconEmoji: iconEmoji,
      requiredProgress: requiredProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'general',
      title: json['title'] as String,
      description: json['description'] as String,
      iconEmoji: json['iconEmoji'] as String,
      requiredProgress: json['requiredProgress'] as int,
      currentProgress: json['currentProgress'] as int? ?? 0,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'description': description,
    'iconEmoji': iconEmoji,
    'requiredProgress': requiredProgress,
    'currentProgress': currentProgress,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };
}
