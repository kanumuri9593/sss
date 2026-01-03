import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/container.dart' as models;
import '../models/item.dart';
import '../models/qr_data.dart';
import '../services/container_service.dart';
import '../services/item_service.dart';
import '../services/qr_service.dart';
import '../services/nfc_tag_storage_service.dart';
import '../widgets/animated_fab.dart';
import '../widgets/glass_components.dart';
import 'item_create_screen.dart';
import 'container_create_screen.dart';
import 'nfc_tag_management_screen.dart';

/// Container Detail Screen
///
/// Shows container information, items in a reorderable list, and nested containers.
class ContainerDetailScreen extends StatefulWidget {
  final String containerId;

  const ContainerDetailScreen({super.key, required this.containerId});

  @override
  State<ContainerDetailScreen> createState() => _ContainerDetailScreenState();
}

class _ContainerDetailScreenState extends State<ContainerDetailScreen> {
  models.Container? _container;
  List<Item> _items = [];
  List<models.Container> _childContainers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Item> _filteredItems = [];
  Timer? _searchDebounceTimer;
  final Map<String, List<Item>> _itemGroups = {}; // Group name -> items
  final List<String> _groupOrder = []; // Order of groups

  @override
  void initState() {
    super.initState();
    _loadContainer();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContainer() async {
    setState(() {
      _isLoading = true;
    });

    final container = ContainerService.getContainer(widget.containerId);
    if (container != null) {
      final items = ItemService.getItemsByContainer(widget.containerId);
      final childContainers = ContainerService.getChildContainers(
        widget.containerId,
      );

      // Organize items into groups
      _organizeItemsIntoGroups(items);

      setState(() {
        _container = container;
        _items = items;
        _childContainers = childContainers;
        _filteredItems = items;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Container not found')));
        Navigator.of(context).pop();
      }
    }
  }

  void _organizeItemsIntoGroups(List<Item> items) {
    _itemGroups.clear();
    _groupOrder.clear();

    // For now, use a simple "Ungrouped" group
    // In the future, items could have a groupId field
    _itemGroups['Ungrouped'] = List.from(items);
    _groupOrder.add('Ungrouped');
  }

  void _onSearchChanged() {
    // Debounce search to avoid excessive rebuilds
    final query = _searchController.text;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_searchController.text != query) {
        return; // Query changed, ignore this update
      }
      setState(() {
        if (query.isEmpty) {
          _filteredItems = _items;
        } else {
          _filteredItems = ItemService.searchItemsInContainer(
            widget.containerId,
            query,
          );
        }
        _organizeItemsIntoGroups(_filteredItems);
      });
    });
  }

  Future<void> _editContainer() async {
    if (_container == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContainerCreateScreen(container: _container),
      ),
    );
    if (result == true) {
      _loadContainer();
    }
  }

  Future<void> _addItem() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemCreateScreen(containerId: widget.containerId),
      ),
    );
    if (result == true) {
      _loadContainer();
    }
  }

  Future<void> _editItem(Item item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ItemCreateScreen(containerId: widget.containerId, item: item),
      ),
    );
    if (result == true) {
      _loadContainer();
    }
  }

  Future<void> _deleteItem(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ItemService.deleteItem(item.id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item deleted')));
        _loadContainer();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
      }
    }
  }

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Sublist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Sublist Name',
            hintText: 'e.g., Electronics, Books, etc.',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_itemGroups.containsKey(result)) {
          _itemGroups[result] = [];
          _groupOrder.add(result);
        }
      });
    }
  }

  Future<void> _reorderItems(
    int oldIndex,
    int newIndex,
    String groupName,
  ) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final items = _itemGroups[groupName] ?? [];
      if (oldIndex < items.length && newIndex < items.length) {
        final item = items.removeAt(oldIndex);
        items.insert(newIndex, item);
        _itemGroups[groupName] = items;
      }
    });

    // TODO: Save order to persistent storage if needed
    // For now, order is only maintained in memory
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Container')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_container == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Container')),
        body: const Center(child: Text('Container not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_container!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showQRCode,
            tooltip: 'View QR Code',
          ),
          IconButton(
            icon: Icon(
              Icons.nfc,
              color: _container!.nfcTagId != null ? Colors.green : null,
            ),
            onPressed: _showNFCOptions,
            tooltip: 'Manage NFC Tag',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editContainer,
            tooltip: 'Edit container',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteContainer,
            tooltip: 'Delete container',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Container Photo and Info
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                if (_container!.photoPath != null)
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.file(
                      File(_container!.photoPath!),
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Text(
                              _container!.typeIcon,
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _container!.typeIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _container!.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _container!.typeDisplayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_container!.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _container!.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (_container!.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _container!.tags.map((tag) {
                            return Chip(label: Text(tag));
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Child Containers
          if (_childContainers.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nested Containers (${_childContainers.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _childContainers.length,
                        itemBuilder: (context, index) {
                          final child = _childContainers[index];
                          return SizedBox(
                            width: 200,
                            child: Card(
                              child: ListTile(
                                leading: Text(
                                  child.typeIcon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                title: Text(child.name),
                                subtitle: Text(child.typeDisplayName),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ContainerDetailScreen(
                                                containerId: child.id,
                                              ),
                                        ),
                                      )
                                      .then((result) {
                                        if (result == true) {
                                          _loadContainer();
                                        }
                                      });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          // Items Header with Create Sublist button
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items (${_filteredItems.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Sublist'),
                  ),
                ],
              ),
            ),
          ),
          // Items by Group
          if (_filteredItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isEmpty
                          ? 'No items yet'
                          : 'No items found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_searchController.text.isEmpty) ...[
                      const SizedBox(height: 24),
                      GlassButton(
                        onPressed: _addItem,
                        glowColor: Theme.of(context).colorScheme.primary,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add Item',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ..._groupOrder.map((groupName) {
              final groupItems = _itemGroups[groupName] ?? [];
              if (groupItems.isEmpty && groupName != 'Ungrouped') {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverMainAxisGroup(
                slivers: [
                  // Group Header
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Text(
                            groupName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${groupItems.length})',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Items in Group (Reorderable)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverReorderableList(
                      itemCount: groupItems.length,
                      onReorder: (oldIndex, newIndex) {
                        _reorderItems(oldIndex, newIndex, groupName);
                      },
                      itemBuilder: (context, index) {
                        final item = groupItems[index];
                        return ReorderableDragStartListener(
                          key: ValueKey(item.id),
                          index: index,
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: item.imagePaths.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: FileImage(
                                        File(item.imagePaths.first),
                                      ),
                                      onBackgroundImageError: (_, __) {},
                                    )
                                  : CircleAvatar(
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                      ),
                                    ),
                              title: Text(item.name),
                              subtitle: item.description != null
                                  ? Text(
                                      item.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editItem(item),
                                    tooltip: 'Edit item',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteItem(item),
                                    tooltip: 'Delete item',
                                  ),
                                ],
                              ),
                              onTap: () => _editItem(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
      floatingActionButton: _filteredItems.isNotEmpty
          ? AnimatedFAB(
              onPressed: _addItem,
              tooltip: 'Add item',
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
    );
  }

  Future<void> _showNFCOptions() async {
    if (_container == null) return;

    final hasNFCTag = _container!.nfcTagId != null;
    NFCTagStoredRegistration? linkedTag;

    if (hasNFCTag) {
      await NFCTagStorageService.initialize();
      linkedTag = NFCTagStorageService.getTagByPhysicalId(
        _container!.nfcTagId!,
      );
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: hasNFCTag ? Colors.green : Colors.grey,
                  child: const Icon(Icons.nfc, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasNFCTag ? 'NFC Tag Linked' : 'No NFC Tag',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (hasNFCTag && linkedTag != null)
                        Text(
                          linkedTag.title,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (hasNFCTag) ...[
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Tag Details'),
                onTap: () {
                  Navigator.pop(context);
                  if (linkedTag != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NFCTagManagementScreen(containerId: _container!.id),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Change NFC Tag'),
                onTap: () async {
                  Navigator.pop(context);
                  await _linkNewNFCTag();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: const Text(
                  'Unlink NFC Tag',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _unlinkNFCTag();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Register & Link NFC Tag'),
                subtitle: const Text('Create a new NFC tag for this container'),
                onTap: () async {
                  Navigator.pop(context);
                  await _linkNewNFCTag();
                },
              ),
              ListTile(
                leading: const Icon(Icons.nfc),
                title: const Text('Manage All NFC Tags'),
                subtitle: const Text('View all registered NFC tags'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NFCTagManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _linkNewNFCTag() async {
    if (_container == null) return;

    final result = await Navigator.push<NFCTagStoredRegistration?>(
      context,
      MaterialPageRoute(
        builder: (context) => NFCTagManagementScreen(
          containerId: _container!.id,
          returnOnSuccess: true,
        ),
      ),
    );

    if (result != null) {
      // Reload container to get updated NFC tag ID
      _loadContainer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC tag linked successfully!')),
        );
      }
    }
  }

  Future<void> _unlinkNFCTag() async {
    if (_container == null || _container!.nfcTagId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink NFC Tag'),
        content: const Text('Remove the NFC tag link from this container?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Find and unlink the stored tag
      await NFCTagStorageService.initialize();
      final storedTag = NFCTagStorageService.getTagByPhysicalId(
        _container!.nfcTagId!,
      );
      if (storedTag != null) {
        await NFCTagStorageService.unlinkTagFromContainer(storedTag.id);
      }

      await ContainerService.unlinkNFCTag(_container!.id);
      _loadContainer();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('NFC tag unlinked')));
      }
    }
  }

  Future<void> _showQRCode() async {
    if (_container == null) return;

    // Ensure container has a QR code
    String? qrId = _container!.qrCodeId;
    String qrDeepLink;
    String qrCustomIdentifier = '';
    Color qrForegroundColor = Colors.black;
    Color qrBackgroundColor = Colors.white;
    Color qrIdentifierColor = Colors.black;

    // Load existing QR code or generate new one
    if (qrId != null) {
      final qrData = QRService.getQRDataById(qrId);
      if (qrData != null) {
        qrDeepLink = qrData.buildDeepLink();
        qrCustomIdentifier = qrData.customIdentifier ?? '';
      } else {
        // QR data not found, generate new one
        final deepLink = _container!.buildDeepLink();
        qrDeepLink = QRService.generateDeepLink(
          data: deepLink,
          category: 'Container',
        );
        qrId = QRData.extractIdFromDeepLink(qrDeepLink);
        if (qrId != null) {
          await ContainerService.linkQRCode(_container!.id, qrId);
          // Reload container to get updated QR code ID
          _loadContainer();
        }
      }
    } else {
      // No QR code exists, generate one
      final deepLink = _container!.buildDeepLink();
      qrDeepLink = QRService.generateDeepLink(
        data: deepLink,
        category: 'Container',
      );
      qrId = QRData.extractIdFromDeepLink(qrDeepLink);
      if (qrId != null) {
        await ContainerService.linkQRCode(_container!.id, qrId);
        // Reload container to get updated QR code ID
        _loadContainer();
      }
    }

    // Show QR code in a dialog
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => _QRCodeDialog(
          container: _container!,
          qrDeepLink: qrDeepLink,
          qrCustomIdentifier: qrCustomIdentifier,
          qrForegroundColor: qrForegroundColor,
          qrBackgroundColor: qrBackgroundColor,
          qrIdentifierColor: qrIdentifierColor,
          onQRUpdated: () {
            _loadContainer();
          },
        ),
      );
    }
  }

  Future<void> _deleteContainer() async {
    if (_container == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Container'),
        content: Text(
          'Are you sure you want to delete "${_container!.name}"? This will also delete all items and nested containers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ContainerService.deleteContainer(
        widget.containerId,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Container deleted')));
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete container')),
        );
      }
    }
  }
}

/// Dialog for displaying and managing container QR code
class _QRCodeDialog extends StatefulWidget {
  final models.Container container;
  final String qrDeepLink;
  final String qrCustomIdentifier;
  final Color qrForegroundColor;
  final Color qrBackgroundColor;
  final Color qrIdentifierColor;
  final VoidCallback onQRUpdated;

  const _QRCodeDialog({
    required this.container,
    required this.qrDeepLink,
    required this.qrCustomIdentifier,
    required this.qrForegroundColor,
    required this.qrBackgroundColor,
    required this.qrIdentifierColor,
    required this.onQRUpdated,
  });

  @override
  State<_QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<_QRCodeDialog> {
  late String _qrDeepLink;
  late String _qrCustomIdentifier;
  late Color _qrForegroundColor;
  late Color _qrBackgroundColor;
  late Color _qrIdentifierColor;
  final _qrRepaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _qrDeepLink = widget.qrDeepLink;
    _qrCustomIdentifier = widget.qrCustomIdentifier;
    _qrForegroundColor = widget.qrForegroundColor;
    _qrBackgroundColor = widget.qrBackgroundColor;
    _qrIdentifierColor = widget.qrIdentifierColor;
  }

  Future<void> _editQRCode() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _QREditDialog(
        customIdentifier: _qrCustomIdentifier,
        foregroundColor: _qrForegroundColor,
        backgroundColor: _qrBackgroundColor,
        identifierColor: _qrIdentifierColor,
      ),
    );

    if (result != null) {
      setState(() {
        _qrCustomIdentifier = result['customIdentifier'] ?? '';
        _qrForegroundColor = result['foregroundColor'] ?? Colors.black;
        _qrBackgroundColor = result['backgroundColor'] ?? Colors.white;
        _qrIdentifierColor = result['identifierColor'] ?? Colors.black;
      });
      // Regenerate QR with new settings
      _regenerateQRCode();
    }
  }

  void _regenerateQRCode() {
    final deepLink = widget.container.buildDeepLink();
    _qrDeepLink = QRService.generateDeepLink(
      data: deepLink,
      category: 'Container',
      customIdentifier: _qrCustomIdentifier.isEmpty
          ? null
          : _qrCustomIdentifier,
    );

    final qrId = QRData.extractIdFromDeepLink(_qrDeepLink);
    if (qrId != null) {
      ContainerService.linkQRCode(widget.container.id, qrId);
      widget.onQRUpdated();
    }
  }

  Future<void> _downloadQRCode() async {
    try {
      final imageBytes = await QRService.captureWidgetToImage(
        repaintBoundaryKey: _qrRepaintKey,
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture QR code')),
          );
        }
        return;
      }

      final fileName =
          'container_${widget.container.name}_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = await QRService.exportAsPNG(
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QR code saved to $filePath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading QR code: $e')),
        );
      }
    }
  }

  Future<void> _shareQRCode() async {
    try {
      final imageBytes = await QRService.captureWidgetToImage(
        repaintBoundaryKey: _qrRepaintKey,
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture QR code')),
          );
        }
        return;
      }

      final fileName = 'container_${widget.container.name}_qr.png';
      final filePath = await QRService.exportAsPNG(
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (filePath != null) {
        await QRService.shareFile(
          filePath: filePath,
          subject: 'QR Code for ${widget.container.name}',
          text: 'QR Code for container: ${widget.container.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing QR code: $e')));
      }
    }
  }

  Widget _buildQRWidget({double size = 250}) {
    final qrWidget = QrImageView(
      data: _qrDeepLink,
      size: size,
      backgroundColor: _qrBackgroundColor,
      foregroundColor: _qrForegroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (_qrCustomIdentifier.isEmpty) {
      return qrWidget;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        qrWidget,
        Container(
          width: size * 0.2,
          height: size * 0.2,
          decoration: BoxDecoration(
            color: _qrBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _qrCustomIdentifier,
              style: TextStyle(
                fontSize: _qrCustomIdentifier.length > 1
                    ? size * 0.15
                    : size * 0.12,
                fontWeight: FontWeight.bold,
                color: _qrIdentifierColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Container QR Code',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Scan this QR code to quickly access this container',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: RepaintBoundary(
                  key: _qrRepaintKey,
                  child: _buildQRWidget(size: 250),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _editQRCode,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit QR'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _downloadQRCode,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _shareQRCode,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for editing QR code appearance
class _QREditDialog extends StatefulWidget {
  final String customIdentifier;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color identifierColor;

  const _QREditDialog({
    required this.customIdentifier,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.identifierColor,
  });

  @override
  State<_QREditDialog> createState() => _QREditDialogState();
}

class _QREditDialogState extends State<_QREditDialog> {
  late TextEditingController _identifierController;
  late Color _foregroundColor;
  late Color _backgroundColor;
  late Color _identifierColor;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(
      text: widget.customIdentifier,
    );
    _foregroundColor = widget.foregroundColor;
    _backgroundColor = widget.backgroundColor;
    _identifierColor = widget.identifierColor;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit QR Code'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Custom Identifier (Letter/Emoji)',
                hintText: 'e.g., A, 📦, etc.',
                helperText: 'Optional: Add a letter or emoji in the center',
              ),
              maxLength: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Foreground Color'),
              trailing: _ColorPickerButton(
                color: _foregroundColor,
                onColorChanged: (color) {
                  setState(() {
                    _foregroundColor = color;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Background Color'),
              trailing: _ColorPickerButton(
                color: _backgroundColor,
                onColorChanged: (color) {
                  setState(() {
                    _backgroundColor = color;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Identifier Color'),
              trailing: _ColorPickerButton(
                color: _identifierColor,
                onColorChanged: (color) {
                  setState(() {
                    _identifierColor = color;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'customIdentifier': _identifierController.text,
              'foregroundColor': _foregroundColor,
              'backgroundColor': _backgroundColor,
              'identifierColor': _identifierColor,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Simple color picker button
class _ColorPickerButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const _ColorPickerButton({required this.color, required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _ColorPickerDialog(
            initialColor: color,
            onColorSelected: onColorChanged,
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 2),
        ),
      ),
    );
  }
}

/// Color picker dialog
class _ColorPickerDialog extends StatelessWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  final List<Color> _colors = const [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Color'),
      content: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: _colors.map((color) {
          return GestureDetector(
            onTap: () {
              onColorSelected(color);
              Navigator.pop(context);
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: initialColor == color ? Colors.black : Colors.grey,
                  width: initialColor == color ? 3 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
