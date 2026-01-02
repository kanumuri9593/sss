import 'dart:async';
import 'package:flutter/material.dart';
import '../models/container.dart' as models;
import '../services/container_service.dart';
import '../services/storage_service.dart';
import '../services/cache_service.dart';
import '../widgets/container_card.dart';
import 'container_detail_screen.dart';
import 'container_create_screen.dart';
import 'profile_screen.dart';

/// Container List Screen
///
/// Displays all containers in a grid/list view with search functionality.
class ContainerListScreen extends StatefulWidget {
  const ContainerListScreen({super.key});

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<models.Container> _containers = [];
  List<models.Container> _filteredContainers = [];
  bool _isGridView = true;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
    // Initialize cache for performance
    CacheService.initialize();
    // Load containers after a short delay to ensure storage is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContainers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when dependencies change (e.g., when tab becomes visible)
    // This ensures data is fresh when navigating back to this tab
    if (StorageService.isInitialized && _containers.isEmpty) {
      _loadContainers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadContainers();
    }
  }

  void _loadContainers() {
    try {
      // Ensure storage is initialized
      if (!StorageService.isInitialized) {
        debugPrint(
          '[ContainerListScreen] Storage not initialized, skipping load',
        );
        return;
      }

      final containers = ContainerService.getAllContainers();
      debugPrint(
        '[ContainerListScreen] Loaded ${containers.length} containers',
      );

      if (mounted) {
        setState(() {
          _containers = containers;
          // Reapply search filter if active
          if (_searchController.text.isEmpty) {
            _filteredContainers = _containers;
          } else {
            _filteredContainers = ContainerService.searchContainers(
              _searchController.text,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[ContainerListScreen] Error loading containers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading containers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    // Debounce search to avoid excessive rebuilds
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = _searchController.text;
      setState(() {
        if (query.isEmpty) {
          _filteredContainers = _containers;
        } else {
          _filteredContainers = ContainerService.searchContainers(query);
        }
      });
    });
  }

  Future<void> _refreshContainers() async {
    _loadContainers();
  }

  void _navigateToCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ContainerCreateScreen()),
    );
    // Always reload when returning from create screen
    // to ensure we have the latest data
    _refreshContainers();
  }

  void _navigateToDetail(models.Container container) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContainerDetailScreen(containerId: container.id),
      ),
    );
    // Always reload when returning from detail screen
    // to ensure we have the latest data (in case container was deleted/updated)
    _refreshContainers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Containers'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search containers...',
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
          // Container List/Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshContainers,
              child: _filteredContainers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No containers yet'
                                : 'No containers found',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (_searchController.text.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first container',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : _isGridView
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredContainers.length,
                      itemBuilder: (context, index) {
                        final container = _filteredContainers[index];
                        final itemCount = CacheService.getItemCount(
                          container.id,
                        );
                        final childContainerCount =
                            CacheService.getChildContainerCount(container.id);
                        return RepaintBoundary(
                          child: ContainerCard(
                            container: container,
                            itemCount: itemCount,
                            childContainerCount: childContainerCount,
                            onTap: () => _navigateToDetail(container),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredContainers.length,
                      itemBuilder: (context, index) {
                        final container = _filteredContainers[index];
                        final itemCount = CacheService.getItemCount(
                          container.id,
                        );
                        final childContainerCount =
                            CacheService.getChildContainerCount(container.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: RepaintBoundary(
                            child: ContainerCard(
                              container: container,
                              itemCount: itemCount,
                              childContainerCount: childContainerCount,
                              onTap: () => _navigateToDetail(container),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        tooltip: 'Create container',
        child: const Icon(Icons.add),
      ),
    );
  }
}
