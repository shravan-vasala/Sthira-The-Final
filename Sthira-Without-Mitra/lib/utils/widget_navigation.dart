/// Launcher links contain an action, never a persisted date or account.
const widgetActions = {'home', 'steps', 'meals', 'workout'};

String? widgetActionForUri(Uri uri) {
  if (uri.scheme.isNotEmpty && uri.scheme != 'trufit') return null;
  final segments = uri.pathSegments;
  if (segments.length == 2 &&
      segments.first == 'widget' &&
      widgetActions.contains(segments.last) &&
      (uri.host.isEmpty || uri.host == 'app')) {
    return segments.last;
  }
  // Older installed widgets keep their pending intents until refreshed.
  if (uri.scheme != 'trufit') return null;
  if (uri.host == 'progress' &&
      uri.path.isEmpty &&
      uri.queryParameters['metric'] == 'steps')
    return 'steps';
  if (uri.host == 'home') {
    if (uri.path.isEmpty || uri.path == '/') return 'home';
    if (uri.path == '/meals') return 'meals';
    if (uri.path == '/workout/today') return 'workout';
  }
  return null;
}

String? normalizeWidgetLocation(Uri uri) {
  final action = widgetActionForUri(uri);
  return action == null ? null : '/widget/$action';
}
