import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/container.dart';
import '../../application/services/container_service.dart';
import '../states/container_state.dart';
import '../providers/service_providers.dart';

/// Container Controller (Notifier)
///
/// Manages container state and operations in the presentation layer.
class ContainerController extends StateNotifier<ContainerState> {
  final ContainerApplicationService _service;

  ContainerController(this._service) : super(ContainerInitial()) {
    loadContainers();
  }

  /// Load all containers
  Future<void> loadContainers() async {
    state = ContainerLoading();
    try {
      final containers = _service.getAllContainers();
      state = ContainerLoaded(containers);
    } catch (e) {
      state = ContainerError(e.toString());
    }
  }

  /// Load root containers only
  Future<void> loadRootContainers() async {
    state = ContainerLoading();
    try {
      final containers = _service.getRootContainers();
      state = ContainerLoaded(containers);
    } catch (e) {
      state = ContainerError(e.toString());
    }
  }

  /// Create a new container
  Future<bool> createContainer(Container container) async {
    try {
      await _service.createContainer(container);
      await loadContainers();
      return true;
    } catch (e) {
      state = ContainerError(e.toString());
      return false;
    }
  }

  /// Update a container
  Future<bool> updateContainer(Container container) async {
    try {
      final updated = await _service.updateContainer(container);
      if (updated != null) {
        await loadContainers();
        return true;
      }
      return false;
    } catch (e) {
      state = ContainerError(e.toString());
      return false;
    }
  }

  /// Delete a container
  Future<bool> deleteContainer(String id) async {
    try {
      final success = await _service.deleteContainer(id);
      if (success) {
        await loadContainers();
      }
      return success;
    } catch (e) {
      state = ContainerError(e.toString());
      return false;
    }
  }

  /// Search containers
  Future<void> searchContainers(String query) async {
    state = ContainerLoading();
    try {
      final containers = await _service.searchContainers(query);
      state = ContainerLoaded(containers);
    } catch (e) {
      state = ContainerError(e.toString());
    }
  }

  /// Search containers by tags
  Future<void> searchContainersByTags(List<String> tags) async {
    state = ContainerLoading();
    try {
      final containers = await _service.searchContainersByTags(tags);
      state = ContainerLoaded(containers);
    } catch (e) {
      state = ContainerError(e.toString());
    }
  }

  /// Link QR code to container
  Future<bool> linkQRCode(String containerId, String qrCodeId) async {
    try {
      final success = await _service.linkQRCode(containerId, qrCodeId);
      if (success) {
        await loadContainers();
      }
      return success;
    } catch (e) {
      state = ContainerError(e.toString());
      return false;
    }
  }

  /// Link NFC tag to container
  Future<bool> linkNFCTag(String containerId, String nfcTagId) async {
    try {
      final success = await _service.linkNFCTag(containerId, nfcTagId);
      if (success) {
        await loadContainers();
      }
      return success;
    } catch (e) {
      state = ContainerError(e.toString());
      return false;
    }
  }

  /// Get container by ID (synchronous, from current state)
  Container? getContainerById(String id) {
    if (state is ContainerLoaded) {
      final loadedState = state as ContainerLoaded;
      return loadedState.containers.firstWhere(
        (c) => c.id == id,
        orElse: () => _service.getContainer(id)!,
      );
    }
    return _service.getContainer(id);
  }
}

/// Container Controller Provider
final containerControllerProvider =
    StateNotifierProvider<ContainerController, ContainerState>((ref) {
  final service = ref.watch(containerServiceProvider);
  return ContainerController(service);
});

/// Single Container State Provider
final singleContainerProvider = FutureProvider.family<Container?, String>((ref, id) async {
  final service = ref.watch(containerServiceProvider);
  return service.getContainer(id);
});
