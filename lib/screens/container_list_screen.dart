import 'package:flutter/material.dart';
import '../models/container.dart' as models;
import '../services/container_service.dart';
import '../widgets/container_card.dart';
import 'container_detail_screen.dart';
import 'container_create_screen.dart';

/// Container List Screen
///
/// Displays all containers in a grid/list view with search functionality.
class ContainerListScreen extends StatefulWidget {
  const ContainerListScreen({super.key});

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<models.Container> _containers = [];
  List<models.Container> _filteredContainers = [];
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadContainers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadContainers() {
    setState(() {
      _containers = ContainerService.getAllContainers();
      _filteredContainers = _containers;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      if (query.isEmpty) {
        _filteredContainers = _containers;
      } else {
        _filteredContainers = ContainerService.searchContainers(query);
      }
    });
  }

  Future<void> _refreshContainers() async {
    _loadContainers();
  }

  void _navigateToCreate() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContainerCreateScreen(),
      ),
    );
    if (result == true) {
      _refreshContainers();
    }
  }

  void _navigateToDetail(models.Container container) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContainerDetailScreen(containerId: container.id),
      ),
    );
    if (result == true) {
      _refreshContainers();
    }
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No containers yet'
                                : 'No containers found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (_searchController.text.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first container',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : _isGridView
                      ? GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredContainers.length,
                          itemBuilder: (context, index) {
                            final container = _filteredContainers[index];
                            return ContainerCard(
                              container: container,
                              onTap: () => _navigateToDetail(container),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredContainers.length,
                          itemBuilder: (context, index) {
                            final container = _filteredContainers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ContainerCard(
                                container: container,
                                onTap: () => _navigateToDetail(container),
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
        child: const Icon(Icons.add),
        tooltip: 'Create container',
      ),
    );
  }
}
