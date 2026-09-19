import 'package:isar/isar.dart';

part 'coach_note.g.dart';

@collection
class CoachNote {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String date;
  final String note;
  final bool isAi;

  CoachNote({required this.date, required this.note, required this.isAi});

  Map<String, dynamic> toJson() {
    return {'date': date, 'note': note, 'isAi': isAi};
  }

  factory CoachNote.fromJson(Map<String, dynamic> json) {
    return CoachNote(
      date: json['date'] as String,
      note: json['note'] as String,
      isAi: json['isAi'] as bool? ?? false,
    );
  }
}
