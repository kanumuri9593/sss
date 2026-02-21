import '../../models/container.dart';
import '../datasources/local_storage_data_source.dart';

/// Container Repository
///
/// Provides a clean API for container data operations.
/// Abstracts data source implementation details from the application layer.
abstract class ContainerRepository {
  Future<Container> createContainer(Container container);
  Container? getContainer(String id);
  List<Container> getAllContainers();
  List<Container> getRootContainers();
  List<Container> getChildContainers(String parentId);
  Future<Container?> updateContainer(Container container);
  Future<bool> deleteContainer(String id);
  Future<List<Container>> searchContainers(String query);
  Future<List<Container>> searchContainersByTags(List<String> tags);
  Container? getContainerByQRCode(String qrCodeId);
  Container? getContainerByNFCTag(String nfcTagId);
  bool canNestContainer(String containerId, String parentContainerId);
  Future<bool> moveContainer(String containerId, String? newParentContainerId);
}

/// Implementation of ContainerRepository using Hive
class ContainerRepositoryImpl implements ContainerRepository {
  final LocalStorageDataSource _dataSource;

  ContainerRepositoryImpl(this._dataSource);

  @override
  Future<Container> createContainer(Container container) async {
    await _dataSource.saveContainer(container);
    return container;
  }

  @override
  Container? getContainer(String id) {
    return _dataSource.getContainer(id);
  }

  @override
  List<Container> getAllContainers() {
    return _dataSource.getAllContainers();
  }

  @override
  List<Container> getRootContainers() {
    return _dataSource.getAllContainers()
        .where((container) => container.parentContainerId == null)
        .toList();
  }

  @override
  List<Container> getChildContainers(String parentId) {
    return _dataSource.getAllContainers()
        .where((container) => container.parentContainerId == parentId)
        .toList();
  }

  @override
  Future<Container?> updateContainer(Container container) async {
    final updated = container.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _dataSource.saveContainer(updated);
    return updated;
  }

  @override
  Future<bool> deleteContainer(String id) async {
    try {
      await _dataSource.deleteContainer(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Container>> searchContainers(String query) async {
    if (query.isEmpty) {
      return getAllContainers();
    }

    final lowerQuery = query.toLowerCase();
    final containers = getAllContainers();

    return containers.where((container) {
      if (container.name.toLowerCase().contains(lowerQuery)) return true;
      if (container.description?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      if (container.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        return true;
      }
      if (container.qrCodeId?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      if (container.nfcTagId?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Future<List<Container>> searchContainersByTags(List<String> tags) async {
    if (tags.isEmpty) {
      return getAllContainers();
    }

    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();
    final containers = getAllContainers();

    return containers.where((container) {
      final containerTags = container.tags.map((t) => t.toLowerCase()).toSet();
      return lowerTags.intersection(containerTags).isNotEmpty;
    }).toList();
  }

  @override
  Container? getContainerByQRCode(String qrCodeId) {
    try {
      return getAllContainers().firstWhere(
        (container) => container.qrCodeId == qrCodeId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Container? getContainerByNFCTag(String nfcTagId) {
    try {
      return getAllContainers().firstWhere(
        (container) => container.nfcTagId == nfcTagId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  bool canNestContainer(String containerId, String parentContainerId) {
    if (containerId == parentContainerId) {
      return false;
    }

    final parent = getContainer(parentContainerId);
    if (parent == null) {
      return true;
    }

    String? currentParentId = parent.parentContainerId;
    while (currentParentId != null) {
      if (currentParentId == containerId) {
        return false;
      }
      final currentParent = getContainer(currentParentId);
      currentParentId = currentParent?.parentContainerId;
    }

    return true;
  }

  @override
  Future<bool> moveContainer(String containerId, String? newParentContainerId) async {
    if (newParentContainerId != null &&
        !canNestContainer(containerId, newParentContainerId)) {
      return false;
    }

    final container = getContainer(containerId);
    if (container == null) {
      return false;
    }

    final updated = container.copyWith(parentContainerId: newParentContainerId);
    await updateContainer(updated);
    return true;
  }
}
