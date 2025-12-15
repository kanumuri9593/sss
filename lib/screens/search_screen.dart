import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/item.dart';
import '../models/container.dart' as models;
import '../services/item_service.dart';
import '../services/container_service.dart';
import '../services/image_recognition_service.dart';
import '../widgets/item_card.dart';
import '../widgets/container_card.dart';
import '../utils/file_utils.dart';
import 'container_detail_screen.dart';

/// Search Screen
/// 
/// Unified search interface for searching items and containers by text, tags, or image.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Item> _itemResults = [];
  List<models.Container> _containerResults = [];
  bool _isSearching = false;
  Set<String> _availableTags = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAvailableTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAvailableTags() {
    final allItems = ItemService.getAllItems();
    final allContainers = ContainerService.getAllContainers();
    final tags = <String>{};
    
    for (final item in allItems) {
      tags.addAll(item.tags);
    }
    for (final container in allContainers) {
      tags.addAll(container.tags);
    }
    
    setState(() {
      _availableTags = tags;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
    });
    _performSearch();
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _itemResults = [];
        _containerResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Search items and containers
    final items = ItemService.searchItems(_searchQuery);
    final containers = ContainerService.searchContainers(_searchQuery);

    setState(() {
      _itemResults = items;
      _containerResults = containers;
      _isSearching = false;
    });
  }

  Future<void> _searchByImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      setState(() {
        _isSearching = true;
      });

      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        // Save image temporarily for processing
        final fileName = 'search_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = await FileUtils.savePhoto(File(pickedFile.path), fileName);
        
        if (savedPath != null) {
          // Get labels from image
          final labels = await ImageRecognitionService.getTopTagSuggestions(savedPath, 10);

          if (labels.isNotEmpty) {
            // Search by tags
            final items = ItemService.searchItemsByTags(labels);
            final containers = ContainerService.searchContainersByTags(labels);

          setState(() {
            _itemResults = items;
            _containerResults = containers;
            _searchQuery = labels.join(', ');
            _searchController.text = _searchQuery;
          });
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No recognizable items found in image'),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No recognizable items found in image'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _searchByTag(String tag) {
    _searchController.text = tag;
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResults = _itemResults.isNotEmpty || _containerResults.isNotEmpty;
    final hasQuery = _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items and containers...',
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
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _searchByImage,
                  tooltip: 'Search by image',
                ),
              ],
            ),
          ),
          // Available Tags
          if (_availableTags.isNotEmpty && !hasQuery)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Tags',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.take(20).map((tag) {
                      return ActionChip(
                        label: Text(tag),
                        onPressed: () => _searchByTag(tag),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !hasQuery
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search for items or containers',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use text search, tags, or image recognition',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : !hasResults
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Container Results
                              if (_containerResults.isNotEmpty) ...[
                                Text(
                                  'Containers (${_containerResults.length})',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _containerResults.length,
                                    itemBuilder: (context, index) {
                                      final container = _containerResults[index];
                                      return SizedBox(
                                        width: 160,
                                        child: ContainerCard(
                                          container: container,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ContainerDetailScreen(
                                                  containerId: container.id,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Item Results
                              if (_itemResults.isNotEmpty) ...[
                                Text(
                                  'Items (${_itemResults.length})',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _itemResults.length,
                                  itemBuilder: (context, index) {
                                    final item = _itemResults[index];
                                    final container = ContainerService
                                        .getContainer(item.containerId);
                                    return ItemCard(
                                      item: item,
                                      onTap: () {
                                        if (container != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ContainerDetailScreen(
                                                containerId: container.id,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
