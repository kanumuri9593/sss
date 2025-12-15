import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/item.dart';
import '../services/item_service.dart';
import '../services/image_recognition_service.dart';
import '../services/container_service.dart';
import '../utils/file_utils.dart';

/// Item Create/Edit Screen
/// 
/// Allows users to create or edit items with photo, tags, and image recognition.
class ItemCreateScreen extends StatefulWidget {
  final String containerId;
  final Item? item;

  const ItemCreateScreen({
    super.key,
    required this.containerId,
    this.item,
  });

  @override
  State<ItemCreateScreen> createState() => _ItemCreateScreenState();
}

class _ItemCreateScreenState extends State<ItemCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _photoPath;
  bool _isLoading = false;
  bool _isProcessingImage = false;
  List<String> _suggestedTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description ?? '';
      _tagsController.text = widget.item!.tags.join(', ');
      _photoPath = widget.item!.photoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _isProcessingImage = true;
        });

        final fileName =
            'item_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedPath = await FileUtils.savePhoto(
          File(pickedFile.path),
          fileName,
        );

        if (savedPath != null) {
          setState(() {
            _photoPath = savedPath;
          });

          // Process image for tag suggestions
          try {
            final suggestions =
                await ImageRecognitionService.getTopTagSuggestions(savedPath, 10);
            setState(() {
              _suggestedTags = suggestions;
            });

            // Auto-add suggested tags if no tags exist
            if (_tagsController.text.isEmpty && suggestions.isNotEmpty) {
              _tagsController.text = suggestions.take(5).join(', ');
            } else if (_tagsController.text.isNotEmpty && suggestions.isNotEmpty) {
              // Show suggestions dialog
              _showTagSuggestions(suggestions);
            }
          } catch (e) {
            debugPrint('Error processing image: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  void _showTagSuggestions(List<String> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggested Tags'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((tag) {
            final isIncluded = _tagsController.text
                .split(',')
                .any((t) => t.trim().toLowerCase() == tag.toLowerCase());
            return FilterChip(
              label: Text(tag),
              selected: isIncluded,
              onSelected: (selected) {
                final currentTags = _tagsController.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();

                if (selected) {
                  if (!currentTags.any(
                      (t) => t.toLowerCase() == tag.toLowerCase())) {
                    currentTags.add(tag);
                  }
                } else {
                  currentTags.removeWhere(
                      (t) => t.toLowerCase() == tag.toLowerCase());
                }

                _tagsController.text = currentTags.join(', ');
                Navigator.pop(context);
                setState(() {});
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Verify container exists
      final container = ContainerService.getContainer(widget.containerId);
      if (container == null) {
        throw Exception('Container not found');
      }

      if (widget.item != null) {
        // Update existing item
        final updated = widget.item!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          photoPath: _photoPath,
          tags: tags,
        );
        await ItemService.updateItem(updated);
      } else {
        // Create new item
        final item = Item.create(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          containerId: widget.containerId,
          tags: tags,
          photoPath: _photoPath,
        );
        await ItemService.createItem(item);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.item != null;
    final container = ContainerService.getContainer(widget.containerId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Edit Item' : 'New Item'),
            if (container != null)
              Text(
                'in ${container.name}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: _isProcessingImage
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Processing image...',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : _photoPath != null && File(_photoPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.file(
                                  File(_photoPath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                                if (_suggestedTags.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Chip(
                                      avatar: const Icon(Icons.auto_awesome, size: 16),
                                      label: Text('${_suggestedTags.length} tags'),
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add photo',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(AI will suggest tags)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 24),
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g., Winter Jacket',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Tags Field
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tags',
                hintText: 'Comma-separated tags',
                helperText: 'Separate tags with commas. AI suggestions will appear after adding a photo.',
                suffixIcon: _suggestedTags.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: 'View AI suggestions',
                        onPressed: () => _showTagSuggestions(_suggestedTags),
                      )
                    : null,
              ),
            ),
            if (_suggestedTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedTags.take(5).map((tag) {
                  final isIncluded = _tagsController.text
                      .split(',')
                      .any((t) => t.trim().toLowerCase() == tag.toLowerCase());
                  return FilterChip(
                    label: Text(tag),
                    selected: isIncluded,
                    onSelected: (selected) {
                      final currentTags = _tagsController.text
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();

                      if (selected) {
                        if (!currentTags.any(
                            (t) => t.toLowerCase() == tag.toLowerCase())) {
                          currentTags.add(tag);
                        }
                      } else {
                        currentTags.removeWhere(
                            (t) => t.toLowerCase() == tag.toLowerCase());
                      }

                      _tagsController.text = currentTags.join(', ');
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Item' : 'Create Item'),
            ),
          ],
        ),
      ),
    );
  }
}
