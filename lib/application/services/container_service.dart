import '../../models/container.dart';
import '../../models/item.dart';
import '../../data/repositories/container_repository.dart';
import '../../data/repositories/item_repository.dart';

/// Container Service (Application Layer)
///
/// Orchestrates container operations using repositories.
/// Handles business logic like cascading deletes and cache invalidation.
class ContainerApplicationService {
  final ContainerRepository _containerRepository;
  final ItemRepository _itemRepository;

  ContainerApplicationService(
    this._containerRepository,
    this._itemRepository,
  );

  /// Create a new container
  Future<Container> createContainer(Container container) async {
    return await _containerRepository.createContainer(container);
  }

  /// Get a container by ID
  Container? getContainer(String id) {
    return _containerRepository.getContainer(id);
  }

  /// Get all containers
  List<Container> getAllContainers() {
    return _containerRepository.getAllContainers();
  }

  /// Get root containers (containers without a parent)
  List<Container> getRootContainers() {
    return _containerRepository.getRootContainers();
  }

  /// Get child containers
  List<Container> getChildContainers(String parentId) {
    return _containerRepository.getChildContainers(parentId);
  }

  /// Update a container
  Future<Container?> updateContainer(Container container) async {
    return await _containerRepository.updateContainer(container);
  }

  /// Delete a container and all its items and child containers
  Future<bool> deleteContainer(String id) async {
    // Get all child containers recursively
    final childContainers = _getAllChildContainers(id);

    // Delete all child containers first
    for (final child in childContainers) {
      await deleteContainer(child.id);
    }

    // Delete all items in this container
    final items = _itemRepository.getItemsByContainer(id);
    for (final item in items) {
      await _itemRepository.deleteItem(item.id);
    }

    // Delete the container itself
    return await _containerRepository.deleteContainer(id);
  }

  /// Get all child containers recursively
  List<Container> _getAllChildContainers(String parentId) {
    final children = _containerRepository.getChildContainers(parentId);
    final allChildren = <Container>[...children];
    for (final child in children) {
      allChildren.addAll(_getAllChildContainers(child.id));
    }
    return allChildren;
  }

  /// Get items in a container
  List<Item> getItemsInContainer(String containerId) {
    return _itemRepository.getItemsByContainer(containerId);
  }

  /// Search containers
  Future<List<Container>> searchContainers(String query) async {
    return await _containerRepository.searchContainers(query);
  }

  /// Search containers by tags
  Future<List<Container>> searchContainersByTags(List<String> tags) async {
    return await _containerRepository.searchContainersByTags(tags);
  }

  /// Link a QR code to a container
  Future<bool> linkQRCode(String containerId, String qrCodeId) async {
    final container = _containerRepository.getContainer(containerId);
    if (container == null) {
      return false;
    }

    final updated = container.copyWith(qrCodeId: qrCodeId);
    await _containerRepository.updateContainer(updated);
    return true;
  }

  /// Link an NFC tag to a container
  Future<bool> linkNFCTag(String containerId, String nfcTagId) async {
    final container = _containerRepository.getContainer(containerId);
    if (container == null) {
      return false;
    }

    final updated = container.copyWith(nfcTagId: nfcTagId);
    await _containerRepository.updateContainer(updated);
    return true;
  }

  /// Unlink QR code from a container
  Future<bool> unlinkQRCode(String containerId) async {
    final container = _containerRepository.getContainer(containerId);
    if (container == null) {
      return false;
    }

    final updated = container.copyWith(clearQrCodeId: true);
    await _containerRepository.updateContainer(updated);
    return true;
  }

  /// Unlink NFC tag from a container
  Future<bool> unlinkNFCTag(String containerId) async {
    final container = _containerRepository.getContainer(containerId);
    if (container == null) {
      return false;
    }

    final updated = container.copyWith(clearNfcTagId: true);
    await _containerRepository.updateContainer(updated);
    return true;
  }

  /// Get container by QR code ID
  Container? getContainerByQRCode(String qrCodeId) {
    return _containerRepository.getContainerByQRCode(qrCodeId);
  }

  /// Get container by NFC tag ID
  Container? getContainerByNFCTag(String nfcTagId) {
    return _containerRepository.getContainerByNFCTag(nfcTagId);
  }

  /// Check if a container can be nested in another
  bool canNestContainer(String containerId, String parentContainerId) {
    return _containerRepository.canNestContainer(containerId, parentContainerId);
  }

  /// Move a container to a new parent
  Future<bool> moveContainer(String containerId, String? newParentContainerId) async {
    return await _containerRepository.moveContainer(containerId, newParentContainerId);
  }
}
