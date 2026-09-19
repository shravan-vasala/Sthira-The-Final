import 'package:isar/isar.dart';

part 'body_stats.g.dart';

@collection
class BodyStats {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String date;
  final double? waist;
  final double? hips;
  final double? chest;
  final double? leftArm;
  final double? rightArm;
  final double? leftThigh;
  final double? rightThigh;
  final double? neck;
  final String unit; // cm or inches

  BodyStats({
    required this.date,
    this.waist,
    this.hips,
    this.chest,
    this.leftArm,
    this.rightArm,
    this.leftThigh,
    this.rightThigh,
    this.neck,
    this.unit = 'cm',
  });

  factory BodyStats.fromJson(Map<String, dynamic> json) {
    return BodyStats(
      date: json['date'] as String,
      waist: (json['waist'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      leftArm: (json['leftArm'] as num?)?.toDouble(),
      rightArm: (json['rightArm'] as num?)?.toDouble(),
      leftThigh: (json['leftThigh'] as num?)?.toDouble(),
      rightThigh: (json['rightThigh'] as num?)?.toDouble(),
      neck: (json['neck'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'cm',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    if (waist != null) 'waist': waist,
    if (hips != null) 'hips': hips,
    if (chest != null) 'chest': chest,
    if (leftArm != null) 'leftArm': leftArm,
    if (rightArm != null) 'rightArm': rightArm,
    if (leftThigh != null) 'leftThigh': leftThigh,
    if (rightThigh != null) 'rightThigh': rightThigh,
    if (neck != null) 'neck': neck,
    'unit': unit,
  };

  BodyStats copyWith({
    double? waist,
    double? hips,
    double? chest,
    double? leftArm,
    double? rightArm,
    double? leftThigh,
    double? rightThigh,
    double? neck,
    String? unit,
  }) {
    return BodyStats(
      date: date,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      chest: chest ?? this.chest,
      leftArm: leftArm ?? this.leftArm,
      rightArm: rightArm ?? this.rightArm,
      leftThigh: leftThigh ?? this.leftThigh,
      rightThigh: rightThigh ?? this.rightThigh,
      neck: neck ?? this.neck,
      unit: unit ?? this.unit,
    );
  }

  @ignore
  Map<String, double?> get allMeasurements => {
    'Waist': waist,
    'Hips': hips,
    'Chest': chest,
    'Left Arm': leftArm,
    'Right Arm': rightArm,
    'Left Thigh': leftThigh,
    'Right Thigh': rightThigh,
    'Neck': neck,
  };
}
