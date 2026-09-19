/// Shared exact-match identity for personal corrections and bundled aliases.
/// Preserve native-script letters/marks; display names remain untouched.
String canonicalFoodName(String input) => input
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}\s]', unicode: true), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');
