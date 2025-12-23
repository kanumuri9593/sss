import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/container.dart' as models;
import '../services/image_cache_service.dart';

/// Item Card Widget
///
/// Displays an item in a card format with photo, name, and tags.
/// Performance optimized: container is passed as parameter instead of being
/// looked up on every build.
class ItemCard extends StatelessWidget {
  final Item item;
  final models.Container? container; // Optional container for display
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ItemCard({
    super.key,
    required this.item,
    this.container,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final displayContainer = container;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item Photo
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPhoto(context),
            ),
            // Item Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Name
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Container name (if available)
                  if (displayContainer != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayContainer.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Tags - Compact indicator
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.tags.length == 1
                                ? item.tags.first
                                : '${item.tags.length} tags',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    // Use imagePaths if available, otherwise fall back to photoPath for migration
    final imagePath = item.imagePaths.isNotEmpty
        ? item.imagePaths.first
        : item.photoPath;

    if (imagePath != null) {
      final imageProvider = ImageCacheService.getImageProvider(
        imagePath,
        cacheWidth: 400,
      );

      if (imageProvider != null) {
        return Stack(
          children: [
            Image(
              image: imageProvider,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(context);
              },
            ),
            // Show image count badge if multiple images
            if (item.imagePaths.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${item.imagePaths.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 48,
        ),
      ),
    );
  }
}
