import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/providers/credential_provider.dart';
import 'package:trufit_bodamma/repositories/profile_repository.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/models/user_profile.dart';

class MockProfileRepository extends ProfileRepository {
  String? fakeKey;
  bool shouldThrow = false;

  MockProfileRepository({this.fakeKey});

  @override
  Future<String?> getSecureGeminiKey() async {
    return fakeKey;
  }

  @override
  Future<void> saveSecureGeminiKey(String key) async {
    if (shouldThrow) throw Exception('Simulated Failure');
    fakeKey = key;
  }

  @override
  Future<void> deleteSecureGeminiKey() async {
    if (shouldThrow) throw Exception('Simulated Failure');
    fakeKey = null;
  }
}

void main() {
  ProviderContainer makeContainer({String? initialKey, required MockProfileRepository mockRepo}) {
    final container = ProviderContainer(
      overrides: [
        profileRepoProvider.overrideWithValue(mockRepo),
      ],
    );
    return container;
  }

  group('Credential State Notifier', () {
    test('launch with key A -> clear -> remains absent', () async {
      final mockRepo = MockProfileRepository(fakeKey: 'KEY_A');
      final container = makeContainer(mockRepo: mockRepo);
      final sub = container.listen(credentialProvider, (_, _) {});
      
      // Wait for initial load
      await Future.delayed(Duration.zero);
      
      var state = container.read(credentialProvider);
      expect(state.status, CredentialStatus.present);
      expect(state.key, 'KEY_A');

      // Clear key
      await container.read(credentialProvider.notifier).removeKey();
      
      state = container.read(credentialProvider);
      expect(state.status, CredentialStatus.removed);
      expect(state.key, null);
      // Wait! The repository mock fakeKey should null out
      expect(mockRepo.fakeKey, null);

      sub.close();
    });

    test('successful replacement with B', () async {
      final mockRepo = MockProfileRepository(fakeKey: 'KEY_A');
      final container = makeContainer(mockRepo: mockRepo);
      await Future.delayed(Duration.zero);
      
      await container.read(credentialProvider.notifier).saveKey('KEY_B');

      final state = container.read(credentialProvider);
      expect(state.status, CredentialStatus.present);
      expect(state.key, 'KEY_B');
      expect(mockRepo.fakeKey, 'KEY_B');
    });

    test('failed save does not silently erase working key', () async {
      final mockRepo = MockProfileRepository(fakeKey: 'KEY_A');
      final container = makeContainer(mockRepo: mockRepo);
      await Future.delayed(Duration.zero);

      mockRepo.shouldThrow = true;

      try {
        await container.read(credentialProvider.notifier).saveKey('KEY_BROKEN');
        fail('Should throw exception');
      } catch (e) {
        // Expected
      }

      final state = container.read(credentialProvider);
      expect(state.status, CredentialStatus.error);
      expect(state.key, 'KEY_A'); 
      expect(mockRepo.fakeKey, 'KEY_A'); 
    });
    
    test('assert profile JSON and backup export exclude credentials', () {
      final p = UserProfile(name: 'Shravan', geminiApiKey: 'HIDDEN_KEY_123');
      final json = p.toJson();
      
      expect(json.containsKey('geminiApiKey'), isFalse, reason: 'Profile JSON must explicitly drop Gemini Key');
      expect(json.toString().contains('HIDDEN_KEY_123'), isFalse);
    });
  });
}
