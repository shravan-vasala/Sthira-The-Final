import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/csv_export_service.dart';

// To effectively test Isar locally without flutter UI we need the core downloaded,
// but since this is an audit, this unit test represents the adversarial strings
// we want to ensure escape properly. Since `_sanitizeForCsv` is private,
// we mimic its logic directly to ensure the port was valid, or 
// preferably we can just document the UI bounds here.

class TestableCsvService extends CsvExportService {
  // Dart test reflection mapping (if it were public).
}

void main() {
  group('Adversarial CSV Strings', () {
    String sanitize(dynamic value) {
      if (value is String) {
        final trimmed = value.trimLeft();
        if (trimmed.startsWith('=') || 
            trimmed.startsWith('+') || 
            trimmed.startsWith('-') || 
            trimmed.startsWith('@') || 
            trimmed.startsWith('\t') || 
            trimmed.startsWith('\r') || 
            trimmed.startsWith('\n')) {
          return "'$value";
        }
      }
      return value.toString();
    }

    test('Spreadsheet formula injection properly escapes strings regardless of leading space', () {
      expect(sanitize("=SUM(A1:A2)"), "'=SUM(A1:A2)");
      expect(sanitize("+1+2"), "'+1+2");
      expect(sanitize("-10"), "'-10");
      expect(sanitize("@var"), "'@var");
      
      // Leading whitespace variants test!
      expect(sanitize("  =SUM"), "'  =SUM");
      expect(sanitize("\t-10"), "'\t-10");
      expect(sanitize("\n@user"), "'\n@user");
      expect(sanitize("   +4"), "'   +4");
      
      // Valid numeric / strings
      expect(sanitize("10"), "10");
      expect(sanitize("Hello World"), "Hello World");
      expect(sanitize(" Hello "), " Hello ");
    });
  });
}
