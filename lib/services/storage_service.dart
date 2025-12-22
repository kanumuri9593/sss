import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/container.dart';
import '../models/item.dart';
import '../models/container_adapter.dart';
import '../models/item_adapter.dart';

/// Storage Service for on-device persistence using Hive
///
/// Manages Hive boxes for containers and items, handles initialization,
/// and provides migration support for future cloud sync.
class StorageService {
  static const String _containersBoxName = 'containers';
  static const String _itemsBoxName = 'items';

  static Box<Container>? _containersBox;
  static Box<Item>? _itemsBox;

  /// Initialize Hive storage
  ///
  /// Must be called before using any storage operations.
  /// Typically called in main.dart during app initialization.
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ContainerAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ItemAdapter());
      }

      // Open boxes
      _containersBox = await Hive.openBox<Container>(_containersBoxName);
      _itemsBox = await Hive.openBox<Item>(_itemsBoxName);

      debugPrint('[Storage] Hive initialized successfully');
      debugPrint('[Storage] Containers box: ${_containersBox!.length} items');
      debugPrint('[Storage] Items box: ${_itemsBox!.length} items');
    } catch (e) {
      debugPrint('[Storage] Error initializing Hive: $e');
      rethrow;
    }
  }

  /// Get the containers box
  static Box<Container> get containersBox {
    if (_containersBox == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    return _containersBox!;
  }

  /// Get the items box
  static Box<Item> get itemsBox {
    if (_itemsBox == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    return _itemsBox!;
  }

  /// Check if storage is initialized
  static bool get isInitialized {
    return _containersBox != null && _itemsBox != null;
  }

  /// Clear all data (for testing or reset)
  static Future<void> clearAll() async {
    if (_containersBox != null) {
      await _containersBox!.clear();
    }
    if (_itemsBox != null) {
      await _itemsBox!.clear();
    }
    debugPrint('[Storage] All data cleared');
  }

  /// Get storage statistics
  static Map<String, int> getStats() {
    return {
      'containers': _containersBox?.length ?? 0,
      'items': _itemsBox?.length ?? 0,
    };
  }

  /// Close all boxes (typically called on app termination)
  static Future<void> close() async {
    await _containersBox?.close();
    await _itemsBox?.close();
    _containersBox = null;
    _itemsBox = null;
    debugPrint('[Storage] Boxes closed');
  }
}
