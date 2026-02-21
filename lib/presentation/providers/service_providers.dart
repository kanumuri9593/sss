import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/services/container_service.dart';
import '../../application/services/item_service.dart';
import '../../application/services/settings_service.dart';
import 'data_providers.dart';

/// Application Service Providers
final containerServiceProvider = Provider<ContainerApplicationService>((ref) {
  final containerRepo = ref.watch(containerRepositoryProvider);
  final itemRepo = ref.watch(itemRepositoryProvider);
  return ContainerApplicationService(containerRepo, itemRepo);
});

final itemServiceProvider = Provider<ItemApplicationService>((ref) {
  final itemRepo = ref.watch(itemRepositoryProvider);
  return ItemApplicationService(itemRepo);
});

final settingsServiceProvider = Provider<SettingsApplicationService>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return SettingsApplicationService(settingsRepo);
});
