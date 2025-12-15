import 'dart:io';
import 'package:flutter/material.dart';
import '../models/container.dart' as models;
import '../models/item.dart';
import '../services/container_service.dart';
import '../services/item_service.dart';
import '../widgets/item_card.dart';
import 'item_create_screen.dart';
import 'container_create_screen.dart';

/// Container Detail Screen
///
/// Shows container information, items, and nested containers.
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

  @override
  void initState() {
    super.initState();
    _loadContainer();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
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

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = ItemService.searchItemsInContainer(widget.containerId, query);
      }
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
          // Items
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Items (${_filteredItems.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
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
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _filteredItems[index];
                  return ItemCard(
                    item: item,
                    container: _container,
                    onTap: () {
                      // TODO: Navigate to item detail/edit
                      _addItem(); // For now, just open edit
                    },
                  );
                },
                childCount: _filteredItems.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
        tooltip: 'Add item',
      ),
    );
  }
}
