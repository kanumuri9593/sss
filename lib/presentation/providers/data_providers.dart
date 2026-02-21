import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_storage_data_source.dart';
import '../../data/repositories/container_repository.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/settings_repository.dart';

/// Data Source Provider
final localStorageDataSourceProvider = Provider<LocalStorageDataSource>((ref) {
  return HiveLocalStorageDataSource();
});

/// Repository Providers
final containerRepositoryProvider = Provider<ContainerRepository>((ref) {
  final dataSource = ref.watch(localStorageDataSourceProvider);
  return ContainerRepositoryImpl(dataSource);
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final dataSource = ref.watch(localStorageDataSourceProvider);
  return ItemRepositoryImpl(dataSource);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dataSource = ref.watch(localStorageDataSourceProvider);
  return SettingsRepositoryImpl(dataSource);
});
