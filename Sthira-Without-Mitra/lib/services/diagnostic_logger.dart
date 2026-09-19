import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

final diagnosticLoggerProvider = ChangeNotifierProvider<DiagnosticLogger>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DiagnosticLogger(prefs);
});

class DiagnosticLog {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? error;
  final String? stackTrace;

  DiagnosticLog({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'ts': timestamp.toIso8601String(),
    'lvl': level,
    'msg': message,
    if (error != null) 'err': error,
    if (stackTrace != null) 'stack': stackTrace,
  };

  factory DiagnosticLog.fromJson(Map<String, dynamic> json) => DiagnosticLog(
    timestamp: DateTime.parse(json['ts']),
    level: json['lvl'],
    message: json['msg'],
    error: json['err'],
    stackTrace: json['stack'],
  );
}

class DiagnosticLogger extends ChangeNotifier {
  static const int _maxLogs = 100;
  static const int _maxBytesPerField =
      4096; // Guard against massive arbitrary payloads crashing JSON
  static const String _prefsKey = 'diagnostic_ring_buffer';

  final SharedPreferences _prefs;
  final Queue<DiagnosticLog> _logs = Queue<DiagnosticLog>();
  int _persistGeneration = 0;
  Future<void> _pendingWrite = Future<void>.value();

  Future<void> flush() => _pendingWrite;

  DiagnosticLogger(this._prefs) {
    _loadFromPrefs();
    if (_logs.isNotEmpty) _saveToPrefs();
  }

  void _loadFromPrefs() {
    try {
      final str = _prefs.getString(_prefsKey);
      if (str != null && str.length <= 2 * 1024 * 1024) {
        final List<dynamic> decoded = jsonDecode(str);
        for (var item in decoded.take(_maxLogs)) {
          try {
            if (item is Map<String, dynamic>) {
              // Re-apply sanity bounds to prevent malicious historical modifications
              final loaded = DiagnosticLog.fromJson(item);
              _logs.addLast(
                DiagnosticLog(
                  timestamp: loaded.timestamp,
                  level: _sanitize(loaded.level),
                  message: _sanitize(loaded.message),
                  error: loaded.error == null ? null : _sanitize(loaded.error!),
                  stackTrace: loaded.stackTrace == null
                      ? null
                      : _sanitize(loaded.stackTrace!),
                ),
              );
            }
          } catch (itemErr) {
            // Ignore single malformed block
          }
        }
        // Ensure bounds upon parsing
        while (_logs.length > _maxLogs) {
          _logs.removeLast();
        }
      }
    } catch (e) {
      debugPrint('DiagnosticLogger failed to load globally: $e');
    }
  }

  void _saveToPrefs() {
    final generation = _persistGeneration;
    final serialized = jsonEncode(
      _logs.map((entry) => entry.toJson()).toList(),
    );
    _pendingWrite = _pendingWrite.then((_) async {
      if (generation != _persistGeneration) return;
      try {
        if (!await _prefs.setString(_prefsKey, serialized)) {
          debugPrint('DiagnosticLogger preferences rejected the write.');
        }
      } catch (_) {
        // Logging must never produce another uncaught async error.
        debugPrint('DiagnosticLogger could not persist diagnostics.');
      }
    });
  }

  String _sanitize(String content) {
    var safe = content;
    safe = safe.replaceAll(
      RegExp(r'AIza[0-9A-Za-z-_]{35}'),
      '[REDACTED_API_KEY]',
    );
    // Scrub secret query parameters (e.g. ?token=..., &key=...)
    safe = safe.replaceAll(
      RegExp(r'([?&])(?:key|token|auth|password|secret|credential)=[^&\s"]+'),
      r'$1[REDACTED_PARAM]',
    );
    // Limit bounds explicitly restricting extreme runaway strings structurally
    if (safe.length > _maxBytesPerField) {
      safe = '${safe.substring(0, _maxBytesPerField)}...[TRUNCATED]';
    }
    return safe;
  }

  void _addLog(
    String level,
    String message, [
    dynamic error,
    StackTrace? stack,
  ]) {
    final log = DiagnosticLog(
      timestamp: DateTime.now(),
      level: level,
      message: _sanitize(message),
      error: error != null ? _sanitize(error.toString()) : null,
      stackTrace: stack != null ? _sanitize(stack.toString()) : null,
    );

    _logs.addFirst(log);
    while (_logs.length > _maxLogs) {
      _logs.removeLast();
    }

    notifyListeners();

    // Serialize best-effort writes so clear cannot be undone by an older write.
    _saveToPrefs();

    // Also echo to console in debug mode
    if (kDebugMode) {
      print(
        '[$level] ${log.message} ${log.error != null ? '\nError: ${log.error}' : ''}',
      );
    }
  }

  void info(String message) => _addLog('INFO', message);
  void warning(String message, [dynamic error, StackTrace? stack]) =>
      _addLog('WARN', message, error, stack);
  void error(String message, [dynamic error, StackTrace? stack]) =>
      _addLog('ERROR', message, error, stack);

  List<DiagnosticLog> getLogs() => _logs.toList();

  void clear() {
    _persistGeneration++;
    _logs.clear();
    notifyListeners();
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _prefs.remove(_prefsKey);
      } catch (_) {
        debugPrint('DiagnosticLogger could not clear persisted diagnostics.');
      }
    });
  }
}

/// A ProviderObserver that catches all Riverpod state errors and logs them
class DiagnosticProviderObserver extends ProviderObserver {
  final DiagnosticLogger logger;
  DiagnosticProviderObserver(this.logger);

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // If it's an AsyncError, log it
    if (newValue is AsyncError) {
      logger.error(
        'Provider ${provider.name ?? provider.runtimeType} AsyncError',
        newValue.error,
        newValue.stackTrace,
      );
    }
  }
}
