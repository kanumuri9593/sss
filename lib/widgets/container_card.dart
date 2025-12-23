import 'package:flutter/material.dart';
import '../models/container.dart' as models;
import '../services/image_cache_service.dart';

/// Container Card Widget
///
/// Displays a container in a card format with photo, name, type, and item count.
/// Performance optimized: item and child container counts are passed as parameters
/// instead of being calculated on every build.
class ContainerCard extends StatelessWidget {
  final models.Container container;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int itemCount;
  final int childContainerCount;

  const ContainerCard({
    super.key,
    required this.container,
    this.onTap,
    this.onLongPress,
    this.itemCount = 0,
    this.childContainerCount = 0,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container Photo
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPhoto(context),
            ),
            // Container Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Name and Type
                  Row(
                    children: [
                      Text(
                        container.typeIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          container.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Type and Count
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          container.typeDisplayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (itemCount > 0 || childContainerCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$itemCount item${itemCount != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (childContainerCount > 0) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '+ $childContainerCount container${childContainerCount != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                  // Tags - Compact indicator
                  if (container.tags.isNotEmpty) ...[
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
                            container.tags.length == 1
                                ? container.tags.first
                                : '${container.tags.length} tags',
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
    if (container.photoPath != null) {
      final imageProvider = ImageCacheService.getImageProvider(
        container.photoPath,
        cacheWidth: 400,
      );

      if (imageProvider != null) {
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(context);
          },
        );
      }
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              container.typeIcon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              container.typeDisplayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
