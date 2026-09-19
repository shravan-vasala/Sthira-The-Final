import '../models/user_profile.dart';

String formatWeight(UserProfile profile, double weightKg) {
  if (profile.useKg) {
    return '${weightKg.toStringAsFixed(1)} kg';
  } else {
    final weightLb = weightKg * 2.20462;
    return '${weightLb.toStringAsFixed(1)} lb';
  }
}

double convertFromKg(UserProfile profile, double weightKg) {
  if (profile.useKg) return weightKg;
  return weightKg * 2.20462;
}

double convertToKg(UserProfile profile, double displayWeight) {
  if (profile.useKg) return displayWeight;
  return displayWeight / 2.20462;
}
