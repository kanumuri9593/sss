import '../../models/item.dart';
import '../../data/repositories/item_repository.dart';

/// Item Service (Application Layer)
///
/// Orchestrates item operations using repositories.
class ItemApplicationService {
  final ItemRepository _itemRepository;

  ItemApplicationService(this._itemRepository);

  /// Create a new item
  Future<Item> createItem(Item item) async {
    return await _itemRepository.createItem(item);
  }

  /// Get an item by ID
  Item? getItem(String id) {
    return _itemRepository.getItem(id);
  }

  /// Get all items
  List<Item> getAllItems() {
    return _itemRepository.getAllItems();
  }

  /// Get items by container ID
  List<Item> getItemsByContainer(String containerId) {
    return _itemRepository.getItemsByContainer(containerId);
  }

  /// Update an item
  Future<Item?> updateItem(Item item) async {
    return await _itemRepository.updateItem(item);
  }

  /// Delete an item
  Future<bool> deleteItem(String id) async {
    return await _itemRepository.deleteItem(id);
  }

  /// Search items
  Future<List<Item>> searchItems(String query) async {
    return await _itemRepository.searchItems(query);
  }

  /// Search items by tags
  Future<List<Item>> searchItemsByTags(List<String> tags) async {
    return await _itemRepository.searchItemsByTags(tags);
  }
}
