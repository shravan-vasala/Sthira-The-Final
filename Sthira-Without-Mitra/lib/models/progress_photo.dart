import 'package:isar/isar.dart';

part 'progress_photo.g.dart';

@collection
class ProgressPhoto {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String path;
  final String date;
  final String pose;
  final double? weight;
  final String? note;

  ProgressPhoto({
    required this.path,
    required this.date,
    required this.pose,
    this.weight,
    this.note,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      path: json['path'] as String,
      date: json['date'] as String,
      pose: json['pose'] as String? ?? 'none',
      weight: (json['weight'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'date': date,
    'pose': pose,
    if (weight != null) 'weight': weight,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}
