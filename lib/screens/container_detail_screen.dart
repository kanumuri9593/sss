import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/container.dart' as models;
import '../models/item.dart';
import '../services/container_service.dart';
import '../services/item_service.dart';
import 'item_create_screen.dart';
import 'container_create_screen.dart';

/// Container Detail Screen
///
/// Shows container information, items in a reorderable list, and nested containers.
class ContainerDetailScreen extends StatefulWidget {
  final String containerId;

  const ContainerDetailScreen({
    super.key,
    required this.containerId,
  });

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
  Map<String, List<Item>> _itemGroups = {}; // Group name -> items
  List<String> _groupOrder = []; // Order of groups

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
      final childContainers = ContainerService.getChildContainers(widget.containerId);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container not found')),
        );
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
      if (_searchController.text != query) return; // Query changed, ignore this update
      setState(() {
        if (query.isEmpty) {
          _filteredItems = _items;
        } else {
          _filteredItems = ItemService.searchItemsInContainer(widget.containerId, query);
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
        builder: (context) => ItemCreateScreen(
          containerId: widget.containerId,
          item: item,
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
        _loadContainer();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete item')),
        );
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

  Future<void> _reorderItems(int oldIndex, int newIndex, String groupName) async {
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
        appBar: AppBar(
          title: const Text('Container'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_container == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Container'),
        ),
        body: const Center(child: Text('Container not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_container!.name),
        actions: [
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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                                leading: Text(child.typeIcon, style: const TextStyle(fontSize: 24)),
                                title: Text(child.name),
                                subtitle: Text(child.typeDisplayName),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ContainerDetailScreen(
                                        containerId: child.id,
                                      ),
                                    ),
                                  ).then((result) {
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
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add an item',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${groupItems.length})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                      backgroundImage: FileImage(File(item.imagePaths.first)),
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
                                  const Icon(Icons.drag_handle),
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
            }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
        tooltip: 'Add item',
      ),
    );
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
      final success = await ContainerService.deleteContainer(widget.containerId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container deleted')),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete container')),
        );
      }
    }
  }
}
