import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/backup_encryption_service.dart';
import 'package:trufit_bodamma/services/backup_service.dart';
import 'package:trufit_bodamma/services/schema_migration_service.dart';
import 'package:trufit_bodamma/interfaces/i_auth_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:archive/archive.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class MockAuthService implements IAuthService {
  @override
  Stream<fb_auth.User?> get authStateChanges => const Stream.empty();

  @override
  fb_auth.User? get currentUser => null;

  @override
  bool get isSignedIn => true;

  @override
  String? get uid => 'test_uid';

  @override
  String? get displayName => 'Test User';

  @override
  String? get email => 'test@example.com';

  @override
  String? get photoUrl => null;

  @override
  Future<fb_auth.User?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

void main() {
  group('Backup Format Dispatch and Encryption', () {
    const password = 'my_super_secret_password';
    late Uint8List validZipBytes;
    late BackupService backupService;

    setUpAll(() {
      backupService = BackupService(MockAuthService());

      final archive = Archive();

      final manifestJson = jsonEncode({
        'schemaVersion': 4,
        'appVersion': 'Sthira V2 Validate',
        'createdAt': DateTime.now().toIso8601String(),
        'totalEntries': 1,
        'uid': 'test_uid',
      });
      archive.addFile(
        ArchiveFile(
          'manifest.json',
          manifestJson.length,
          utf8.encode(manifestJson),
        ),
      );

      final dataJson = jsonEncode({
        for (final name in SchemaMigrationService.collectionNames) name: [],
        'userProfiles': [
          {'id': 1, 'name': 'test'},
        ],
      });
      archive.addFile(
        ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)),
      );

      validZipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
    });

    test('detectFormat identifies formats correctly', () {
      expect(
        BackupEncryptionService.detectFormat(validZipBytes),
        BackupFormat.unencrypted,
      );

      final v2Encrypted = BackupEncryptionService.encryptBytes(
        validZipBytes,
        password,
      );
      expect(
        BackupEncryptionService.detectFormat(v2Encrypted),
        BackupFormat.v2,
      );

      // Unknown TFBK Version
      final unknownV3 = Uint8List.fromList(v2Encrypted);
      unknownV3[4] = 3; // Change version to 3
      expect(
        BackupEncryptionService.detectFormat(unknownV3),
        BackupFormat.unknownVersion,
      );

      // Headersless legacy input
      final keyBytes = sha256.convert(utf8.encode(password)).bytes;
      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encryptedV1 = encrypter.encryptBytes(validZipBytes, iv: iv);
      final out = BytesBuilder();
      out.add(iv.bytes);
      out.add(encryptedV1.bytes);
      final legacyBytes = out.toBytes();

      expect(
        BackupEncryptionService.detectFormat(legacyBytes),
        BackupFormat.v1legacy,
      );
    });

    // --- High-Level verification Tests (Mocking BackupService.verifyBackup) ---
    Future<BackupVerificationResult> runVerify(
      Uint8List payload,
      String? verifyPass,
    ) async {
      final tmpFile = File(
        '${Directory.systemTemp.path}/test_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
      );
      await tmpFile.writeAsBytes(payload);
      final res = await backupService.verifyBackup(
        tmpFile.path,
        password: verifyPass,
      );
      await tmpFile.delete();
      return res;
    }

    test('unencrypted valid zip works', () async {
      final res = await runVerify(validZipBytes, null);
      expect(res.isValid, isTrue);
      expect(res.isEncrypted, isFalse);
      expect(res.totalEntries, 1);
    });

    test('v2 encrypted backup verified successfully', () async {
      final payload = BackupEncryptionService.encryptBytes(
        validZipBytes,
        password,
      );

      // Without password -> fails
      final resNoPwd = await runVerify(payload, null);
      expect(resNoPwd.isValid, isFalse);
      expect(resNoPwd.errorMessage, contains('Password required'));

      // With password -> successes
      final resCorrect = await runVerify(payload, password);
      expect(resCorrect.isValid, isTrue);
      expect(resCorrect.isEncrypted, isTrue);
    });

    test('v2 tampered payload explicitly fails', () async {
      final payload = BackupEncryptionService.encryptBytes(
        validZipBytes,
        password,
      );
      payload[payload.length - 1] ^= 0x01; // Tamper tag

      final resWrong = await runVerify(payload, password);
      expect(resWrong.isValid, isFalse);
      expect(
        resWrong.errorMessage,
        contains('Incorrect password or corrupted file'),
      );
    });

    test(
      'unknown TFBK version throws explicitly and prevents legacy fallback',
      () async {
        final payload = BackupEncryptionService.encryptBytes(
          validZipBytes,
          password,
        );
        payload[4] = 99; // Unknown version

        final res = await runVerify(payload, password);
        expect(res.isValid, isFalse);
        expect(
          res.errorMessage,
          contains('Unsupported backup format version.'),
        );
      },
    );

    test(
      'v1 legacy handles graceful fallback but strictly requires ZIP structural matching',
      () async {
        // 1. Manually create v1 encrypted data
        final keyBytes = sha256.convert(utf8.encode(password)).bytes;
        final key = enc.Key(Uint8List.fromList(keyBytes));
        final iv = enc.IV.fromSecureRandom(16);
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        final encryptedV1 = encrypter.encryptBytes(validZipBytes, iv: iv);
        final out = BytesBuilder();
        out.add(iv.bytes);
        out.add(encryptedV1.bytes);
        final legacyBytes = out.toBytes();

        // Password requirement
        final resNoPwd = await runVerify(legacyBytes, null);
        expect(resNoPwd.isValid, isFalse);
        expect(resNoPwd.errorMessage, contains('Password required'));

        // Good password -> strict zip decode successful
        final resCorrect = await runVerify(legacyBytes, password);
        expect(resCorrect.isValid, isTrue);
        expect(resCorrect.isEncrypted, isTrue);

        // Wrong password -> throws unauthenticated CBC garbage string check (Header check failed)
        final resWrong = await runVerify(legacyBytes, 'wrong_pass');
        expect(resWrong.isValid, isFalse);
        expect(
          resWrong.errorMessage,
          contains('Incorrect legacy password or corrupted file'),
        );
      },
    );
  });
}
