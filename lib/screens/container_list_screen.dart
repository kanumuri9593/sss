import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/container.dart' as models;
import '../services/container_service.dart';
import '../services/storage_service.dart';
import '../services/cache_service.dart';
import '../services/item_service.dart';
import '../widgets/container_card.dart';
import '../widgets/glass_components.dart';
import '../widgets/spring_animations.dart';
import '../widgets/illustrations.dart';
import '../widgets/celebrations.dart';
import '../widgets/animated_fab.dart';
import '../navigation/navigation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Container List Screen - Award-Winning UI Redesign
///
/// Features:
/// - Time-based greeting with stats in glass pills
/// - Animated search bar with spring physics
/// - Staggered masonry grid with parallax effect
/// - Glassmorphism container cards
/// - Custom FAB with celebration animations
class ContainerListScreen extends StatefulWidget {
  const ContainerListScreen({super.key});

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<models.Container> _containers = [];
  List<models.Container> _filteredContainers = [];
  bool _isGridView = true;
  Timer? _searchDebounceTimer;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);

    CacheService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContainers();
      // Request permissions after UI is ready (this ensures app appears in Settings)
      _requestPermissionsIfNeeded();
    });
  }
  
  /// Request permissions proactively after first screen load
  /// This ensures the app appears in iOS Settings
  Future<void> _requestPermissionsIfNeeded() async {
    try {
      // Small delay to ensure UI is fully rendered
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if permissions have been requested before
      final cameraRequested = await PermissionService.hasBeenRequested(ph.Permission.camera);
      final photosRequested = await PermissionService.hasBeenRequested(ph.Permission.photos);
      
      // Only request if not already requested (to avoid annoying users)
      if (!cameraRequested) {
        debugPrint('[ContainerList] Requesting camera permission proactively');
        await PermissionService.requestCameraPermission();
      }
      
      if (!photosRequested) {
        debugPrint('[ContainerList] Requesting photos permission proactively');
        await PermissionService.requestPhotosPermission();
      }
    } catch (e) {
      debugPrint('[ContainerList] Error requesting permissions: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (StorageService.isInitialized && _containers.isEmpty) {
      _loadContainers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadContainers();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '🌅';
    } else if (hour < 17) {
      return '☀️';
    } else {
      return '🌙';
    }
  }

  Future<void> _loadContainers() async {
    try {
      if (!StorageService.isInitialized) {
        debugPrint('[ContainerListScreen] Storage not initialized');
        return;
      }

      final containers = ContainerService.getAllContainers();
      debugPrint(
        '[ContainerListScreen] Loaded ${containers.length} containers',
      );

      List<models.Container> filtered;
      if (_searchController.text.isEmpty) {
        filtered = containers;
      } else {
        filtered = await ContainerService.searchContainers(
          _searchController.text,
        );
      }

      if (mounted) {
        setState(() {
          _containers = containers;
          _filteredContainers = filtered;
        });
      }
    } catch (e) {
      debugPrint('[ContainerListScreen] Error loading containers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading containers: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final query = _searchController.text;

      List<models.Container> results;
      if (query.isEmpty) {
        results = _containers;
      } else {
        results = await ContainerService.searchContainers(query);
      }

      if (mounted) {
        setState(() {
          _filteredContainers = results;
        });
      }
    });
  }

  Future<void> _refreshContainers() async {
    HapticFeedback.mediumImpact();
    await _loadContainers();
  }

  void _navigateToCreate() async {
    HapticFeedback.lightImpact();

    final result = await context.push('/containers/create');

    if (result == true) {
      // Show celebration for new container
      setState(() => _showCelebration = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _showCelebration = false);
        }
      });
    }

    _refreshContainers();
  }

  void _navigateToDetail(models.Container container) async {
    HapticFeedback.selectionClick();
    NavigationHelper.goToContainer(context, container.id);
    _refreshContainers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = ItemService.getAllItems().length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(context),
      body: ConfettiBurst(
        trigger: _showCelebration,
        child: RefreshIndicator(
          onRefresh: _refreshContainers,
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header with greeting and stats
              SliverToBoxAdapter(child: _buildHeader(context, totalItems)),

              // Search Bar
              SliverToBoxAdapter(child: _buildSearchBar(context)),

              // Content
              if (_filteredContainers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else if (_isGridView)
                _buildGrid(context)
              else
                _buildList(context),

              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: _filteredContainers.isNotEmpty
          ? _buildFAB(context)
          : null,
    );
  }

  PreferredSizeWidget _buildGlassAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return GlassAppBar(
      title: Text(
        'My Containers',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              key: ValueKey(_isGridView),
            ),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _isGridView = !_isGridView);
          },
          tooltip: _isGridView ? 'List view' : 'Grid view',
        ),
        SpringScale(
          onTap: () {
            NavigationHelper.goToProfile(context);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int totalItems) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          SpringSlide(
            beginOffset: const Offset(0, 20),
            child: Row(
              children: [
                Text(
                  _getGreeting(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Pills
          SpringSlide(
            beginOffset: const Offset(0, 20),
            delay: const Duration(milliseconds: 100),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                GlassPill(
                  icon: Icons.inventory_2_rounded,
                  text: '${_containers.length} containers',
                  color: theme.colorScheme.primary,
                ),
                GlassPill(
                  icon: Icons.category_rounded,
                  text: '$totalItems items',
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SpringSlide(
      beginOffset: const Offset(0, 20),
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          blur: 15,
          opacity: isDark ? 0.15 : 0.6,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search containers...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        HapticFeedback.selectionClick();
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SpringSlide(
      beginOffset: const Offset(0, 30),
      delay: const Duration(milliseconds: 300),
      child: EmptyStateWidget(
        illustration: _searchController.text.isNotEmpty
            ? const SearchNoResultsIllustration()
            : const NoContainersIllustration(),
        title: _searchController.text.isEmpty
            ? 'No containers yet'
            : 'No containers found',
        subtitle: _searchController.text.isEmpty
            ? 'Tap the + button to create your first container'
            : 'Try adjusting your search',
        action: _searchController.text.isEmpty
            ? GlassButton(
                onPressed: _navigateToCreate,
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
                      'Create Container',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: AnimationLimiter(
        child: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final container = _filteredContainers[index];
            final itemCount = CacheService.getItemCount(container.id);
            final childContainerCount = CacheService.getChildContainerCount(
              container.id,
            );

            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 400),
              columnCount: 2,
              child: ScaleAnimation(
                scale: 0.9,
                child: FadeInAnimation(
                  child: ContainerCard(
                    container: container,
                    itemCount: itemCount,
                    childContainerCount: childContainerCount,
                    onTap: () => _navigateToDetail(container),
                  ),
                ),
              ),
            );
          }, childCount: _filteredContainers.length),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: AnimationLimiter(
        child: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final container = _filteredContainers[index];
            final itemCount = CacheService.getItemCount(container.id);
            final childContainerCount = CacheService.getChildContainerCount(
              container.id,
            );

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 400),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      height: 200,
                      child: ContainerCard(
                        container: container,
                        itemCount: itemCount,
                        childContainerCount: childContainerCount,
                        onTap: () => _navigateToDetail(container),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }, childCount: _filteredContainers.length),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedFAB(
      onPressed: _navigateToCreate,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      tooltip: 'Add container',
    );
  }
}
