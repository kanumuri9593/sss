import '../../models/item.dart';
import '../datasources/local_storage_data_source.dart';

/// Item Repository
///
/// Provides a clean API for item data operations.
abstract class ItemRepository {
  Future<Item> createItem(Item item);
  Item? getItem(String id);
  List<Item> getAllItems();
  List<Item> getItemsByContainer(String containerId);
  Future<Item?> updateItem(Item item);
  Future<bool> deleteItem(String id);
  Future<List<Item>> searchItems(String query);
  Future<List<Item>> searchItemsByTags(List<String> tags);
}

/// Implementation of ItemRepository using Hive
class ItemRepositoryImpl implements ItemRepository {
  final LocalStorageDataSource _dataSource;

  ItemRepositoryImpl(this._dataSource);

  @override
  Future<Item> createItem(Item item) async {
    await _dataSource.saveItem(item);
    return item;
  }

  @override
  Item? getItem(String id) {
    return _dataSource.getItem(id);
  }

  @override
  List<Item> getAllItems() {
    return _dataSource.getAllItems();
  }

  @override
  List<Item> getItemsByContainer(String containerId) {
    return _dataSource.getAllItems()
        .where((item) => item.containerId == containerId)
        .toList();
  }

  @override
  Future<Item?> updateItem(Item item) async {
    final updated = item.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _dataSource.saveItem(updated);
    return updated;
  }

  @override
  Future<bool> deleteItem(String id) async {
    try {
      await _dataSource.deleteItem(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Item>> searchItems(String query) async {
    if (query.isEmpty) {
      return getAllItems();
    }

    final lowerQuery = query.toLowerCase();
    final items = getAllItems();

    return items.where((item) {
      if (item.name.toLowerCase().contains(lowerQuery)) return true;
      if (item.description?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      if (item.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Future<List<Item>> searchItemsByTags(List<String> tags) async {
    if (tags.isEmpty) {
      return getAllItems();
    }

    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();
    final items = getAllItems();

    return items.where((item) {
      final itemTags = item.tags.map((t) => t.toLowerCase()).toSet();
      return lowerTags.intersection(itemTags).isNotEmpty;
    }).toList();
  }
}
