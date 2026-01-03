import 'package:hive_flutter/hive_flutter.dart';
import '../../models/container.dart';
import '../../models/item.dart';
import '../../models/app_settings.dart';
import '../../models/container_adapter.dart';
import '../../models/item_adapter.dart';
import '../../models/app_settings_adapter.dart';

/// Local Storage Data Source
///
/// Handles direct interaction with Hive storage boxes.
/// This is the lowest level data access layer.
abstract class LocalStorageDataSource {
  Future<void> initialize();
  
  // Container operations
  Future<void> saveContainer(Container container);
  Container? getContainer(String id);
  List<Container> getAllContainers();
  Future<void> deleteContainer(String id);
  
  // Item operations
  Future<void> saveItem(Item item);
  Item? getItem(String id);
  List<Item> getAllItems();
  Future<void> deleteItem(String id);
  
  // Settings operations
  Future<void> saveSettings(AppSettings settings);
  AppSettings? getSettings();
}

/// Hive-based implementation of LocalStorageDataSource
class HiveLocalStorageDataSource implements LocalStorageDataSource {
  static const String _containersBoxName = 'containers';
  static const String _itemsBoxName = 'items';
  static const String _settingsBoxName = 'app_settings';
  static const String _settingsKey = 'settings';

  Box<Container>? _containersBox;
  Box<Item>? _itemsBox;
  Box<AppSettings>? _settingsBox;

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ContainerAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    // Open boxes
    _containersBox = await Hive.openBox<Container>(_containersBoxName);
    _itemsBox = await Hive.openBox<Item>(_itemsBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
  }

  @override
  Future<void> saveContainer(Container container) async {
    await _containersBox?.put(container.id, container);
    await _containersBox?.flush();
  }

  @override
  Container? getContainer(String id) {
    return _containersBox?.get(id);
  }

  @override
  List<Container> getAllContainers() {
    return _containersBox?.values.toList() ?? [];
  }

  @override
  Future<void> deleteContainer(String id) async {
    await _containersBox?.delete(id);
    await _containersBox?.flush();
  }

  @override
  Future<void> saveItem(Item item) async {
    await _itemsBox?.put(item.id, item);
    await _itemsBox?.flush();
  }

  @override
  Item? getItem(String id) {
    return _itemsBox?.get(id);
  }

  @override
  List<Item> getAllItems() {
    return _itemsBox?.values.toList() ?? [];
  }

  @override
  Future<void> deleteItem(String id) async {
    await _itemsBox?.delete(id);
    await _itemsBox?.flush();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox?.put(_settingsKey, settings);
  }

  @override
  AppSettings? getSettings() {
    return _settingsBox?.get(_settingsKey);
  }
}
