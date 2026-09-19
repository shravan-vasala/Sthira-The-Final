import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';

enum CredentialStatus { loading, present, removed, error }

class CredentialState {
  final CredentialStatus status;
  final String? key;
  final String? errorMessage;

  const CredentialState({required this.status, this.key, this.errorMessage});

  CredentialState copyWith({
    CredentialStatus? status,
    String? key,
    String? errorMessage,
  }) {
    return CredentialState(
      status: status ?? this.status,
      key: key ?? this.key,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CredentialNotifier extends Notifier<CredentialState> {
  @override
  CredentialState build() {
    _loadInitial();
    return const CredentialState(status: CredentialStatus.loading);
  }

  Future<void> _loadInitial() async {
    try {
      final repo = ref.read(profileRepoProvider);
      final key = await repo.getSecureGeminiKey();
      if (key != null && key.isNotEmpty) {
        state = state.copyWith(
          status: CredentialStatus.present,
          key: key,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: CredentialStatus.removed,
          key: null,
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: CredentialStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> saveKey(String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      await removeKey();
      return;
    }

    try {
      final repo = ref.read(profileRepoProvider);
      await repo.saveSecureGeminiKey(cleanKey);
      state = state.copyWith(
        status: CredentialStatus.present,
        key: cleanKey,
        errorMessage: null,
      );
    } catch (e) {
      // Must not silently erase working key if replacement save failed (as per Prompt 01)
      state = state.copyWith(
        status: CredentialStatus.error,
        errorMessage: 'Failed to securely save API key.',
      );
      throw Exception('Failed to securely save API key.');
    }
  }

  Future<void> removeKey() async {
    try {
      final repo = ref.read(profileRepoProvider);
      await repo.deleteSecureGeminiKey();
      // Direct construction — copyWith can't null-out key due to `key ?? this.key`
      state = const CredentialState(status: CredentialStatus.removed);
    } catch (e) {
      state = state.copyWith(
        status: CredentialStatus.error,
        errorMessage: 'Failed to clear API key.',
      );
      throw Exception('Failed to clear API key.');
    }
  }
}

final credentialProvider =
    NotifierProvider<CredentialNotifier, CredentialState>(
      CredentialNotifier.new,
    );
