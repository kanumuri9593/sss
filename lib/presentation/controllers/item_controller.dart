import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/item.dart';
import '../../application/services/item_service.dart';
import '../states/item_state.dart';
import '../providers/service_providers.dart';

/// Item Controller (Notifier)
///
/// Manages item state and operations in the presentation layer.
class ItemController extends StateNotifier<ItemState> {
  final ItemApplicationService _service;

  ItemController(this._service) : super(ItemInitial());

  /// Load items for a container
  Future<void> loadItemsByContainer(String containerId) async {
    state = ItemLoading();
    try {
      final items = _service.getItemsByContainer(containerId);
      state = ItemLoaded(items);
    } catch (e) {
      state = ItemError(e.toString());
    }
  }

  /// Load all items
  Future<void> loadAllItems() async {
    state = ItemLoading();
    try {
      final items = _service.getAllItems();
      state = ItemLoaded(items);
    } catch (e) {
      state = ItemError(e.toString());
    }
  }

  /// Create a new item
  Future<bool> createItem(Item item) async {
    try {
      await _service.createItem(item);
      await loadItemsByContainer(item.containerId);
      return true;
    } catch (e) {
      state = ItemError(e.toString());
      return false;
    }
  }

  /// Update an item
  Future<bool> updateItem(Item item) async {
    try {
      final updated = await _service.updateItem(item);
      if (updated != null) {
        await loadItemsByContainer(item.containerId);
        return true;
      }
      return false;
    } catch (e) {
      state = ItemError(e.toString());
      return false;
    }
  }

  /// Delete an item
  Future<bool> deleteItem(String id, String containerId) async {
    try {
      final success = await _service.deleteItem(id);
      if (success) {
        await loadItemsByContainer(containerId);
      }
      return success;
    } catch (e) {
      state = ItemError(e.toString());
      return false;
    }
  }

  /// Search items
  Future<void> searchItems(String query) async {
    state = ItemLoading();
    try {
      final items = await _service.searchItems(query);
      state = ItemLoaded(items);
    } catch (e) {
      state = ItemError(e.toString());
    }
  }

  /// Search items by tags
  Future<void> searchItemsByTags(List<String> tags) async {
    state = ItemLoading();
    try {
      final items = await _service.searchItemsByTags(tags);
      state = ItemLoaded(items);
    } catch (e) {
      state = ItemError(e.toString());
    }
  }
}

/// Item Controller Provider
final itemControllerProvider =
    StateNotifierProvider<ItemController, ItemState>((ref) {
  final service = ref.watch(itemServiceProvider);
  return ItemController(service);
});

/// Items by Container Provider
final itemsByContainerProvider = Provider.family<List<Item>, String>((ref, containerId) {
  final service = ref.watch(itemServiceProvider);
  return service.getItemsByContainer(containerId);
});
