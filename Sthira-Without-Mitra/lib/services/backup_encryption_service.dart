import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';

enum BackupFormat { unencrypted, v2, v1legacy, unknownVersion }

class BackupEncryptionService {
  static const _magic = [84, 70, 66, 75]; // 'TFBK'
  static const _version = 2;
  static const _iterations = 150000;

  /// Encrypts data using AES-256-GCM (v2).
  /// Format: magic (4) + version (1) + salt (16) + nonce (12) + ciphertext (includes tag)
  static Uint8List encryptBytes(Uint8List data, String password) {
    final salt = enc.IV.fromSecureRandom(16).bytes;
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, _iterations, 32));
    final keyBytes = derivator.process(
      Uint8List.fromList(utf8.encode(password)),
    );
    final key = enc.Key(keyBytes);

    final nonce = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(data, iv: nonce);

    final out = BytesBuilder();
    out.add(_magic);
    out.addByte(_version);
    out.add(salt);
    out.add(nonce.bytes);
    out.add(encrypted.bytes);
    return out.toBytes();
  }

  static BackupFormat detectFormat(Uint8List data) {
    if (data.length >= 4 &&
        data[0] == _magic[0] &&
        data[1] == _magic[1] &&
        data[2] == _magic[2] &&
        data[3] == _magic[3]) {
      if (data.length > 4 && data[4] == _version) {
        return BackupFormat.v2;
      }
      return BackupFormat.unknownVersion;
    }

    // Check for ZIP magic 'PK\x03\x04' -> [80, 75, 3, 4]
    if (data.length > 4 &&
        data[0] == 80 &&
        data[1] == 75 &&
        data[2] == 3 &&
        data[3] == 4) {
      return BackupFormat.unencrypted;
    }

    // If not TFBK and not plaintext zip, it's possibly headerless v1
    return BackupFormat.v1legacy;
  }

  static Uint8List decryptV2(Uint8List data, String password) {
    // Header: 4 magic + 1 version + 16 salt + 12 nonce = 33 bytes
    if (data.length < 49 || detectFormat(data) != BackupFormat.v2) {
      throw Exception('Invalid v2 encrypted data: too short');
    }

    final salt = data.sublist(5, 21);
    final nonceBytes = data.sublist(21, 33);
    final encryptedBytes = data.sublist(33);

    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, _iterations, 32));
    final keyBytes = derivator.process(
      Uint8List.fromList(utf8.encode(password)),
    );
    final key = enc.Key(keyBytes);

    final nonce = enc.IV(nonceBytes);
    final encrypted = enc.Encrypted(encryptedBytes);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final decryptedList = encrypter.decryptBytes(encrypted, iv: nonce);
    return Uint8List.fromList(decryptedList);
  }

  static Uint8List decryptV1(Uint8List data, String password) {
    if (data.length < 32 || (data.length - 16) % 16 != 0) {
      throw Exception('Invalid v1 encrypted data: too short');
    }

    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));

    final ivBytes = data.sublist(0, 16);
    final encryptedBytes = data.sublist(16);

    final iv = enc.IV(ivBytes);
    final encrypted = enc.Encrypted(encryptedBytes);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decryptedList = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decryptedList);
  }
}
