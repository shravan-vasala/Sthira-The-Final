import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/barcode_food_store.dart';
import '../services/barcode_food_service.dart';
import 'app_providers.dart';

final barcodeFoodServiceProvider = Provider.autoDispose<BarcodeFoodService>((
  ref,
) {
  final service = BarcodeFoodService(country: 'in', language: 'en');
  ref.onDispose(service.dispose);
  return service;
});

final barcodeFoodStoreProvider = Provider.autoDispose<BarcodeFoodStore>((ref) {
  // Rebuild when authentication changes, not only when the screen first opens.
  ref.watch(authStateProvider);
  final account = ref.watch(authServiceProvider).uid ?? 'guest';
  return BarcodeFoodStore(
    ref.watch(sharedPreferencesProvider),
    accountId: account,
  );
});
