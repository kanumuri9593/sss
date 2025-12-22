import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/item.dart';
import '../services/item_service.dart';
import '../services/image_recognition_service.dart';
import '../services/container_service.dart';
import '../utils/file_utils.dart';
import '../widgets/tag_editor_widget.dart';

/// Item Create/Edit Screen
/// 
/// Allows users to create or edit items with multiple photos, tags, and image recognition.
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

  List<String> _imagePaths = [];
  bool _isLoading = false;
  bool _isProcessingImage = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    // Initialize image recognition service
    ImageRecognitionService.initialize();
    
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description ?? '';
      _tags = List.from(widget.item!.tags);
      // Use imagePaths if available, otherwise fall back to photoPath for migration
      _imagePaths = widget.item!.imagePaths.isNotEmpty
          ? List.from(widget.item!.imagePaths)
          : (widget.item!.photoPath != null ? [widget.item!.photoPath!] : []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
            _imagePaths.add(savedPath);
          });

          // Auto-generate and add tags from image
          try {
            final generatedTags = await ImageRecognitionService.processImage(savedPath);
            
            // Merge with existing tags (avoid duplicates)
            final updatedTags = List<String>.from(_tags);
            for (final tag in generatedTags.take(5)) {
              if (!updatedTags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
                updatedTags.add(tag);
              }
            }

            setState(() {
              _tags = updatedTags;
            });
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

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {

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
          imagePaths: _imagePaths,
          tags: _tags,
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
          tags: _tags,
          imagePaths: _imagePaths,
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
            // Images Section
            Text(
              'Images (${_imagePaths.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_imagePaths.isEmpty)
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
                              '(AI will auto-generate tags)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imagePaths.length) {
                      // Add image button
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 200,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline,
                                width: 2,
                              ),
                            ),
                            child: _isProcessingImage
                                ? const Center(
                                    child: CircularProgressIndicator(),
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
                                        'Add Photo',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    }
                    // Image with remove button
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_imagePaths[index]),
                                fit: BoxFit.cover,
                                height: 200,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () => _removeImage(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
            // Tags Field with TagEditorWidget
            TagEditorWidget(
              tags: _tags,
              onTagsChanged: (tags) {
                setState(() {
                  _tags = tags;
                });
              },
              labelText: 'Tags',
              hintText: 'Comma-separated tags',
              helperText: _isProcessingImage
                  ? 'Processing image and generating tags...'
                  : 'Tags will be auto-generated when you add a photo. Separate tags with commas.',
            ),
            if (_isProcessingImage) ...[
              const SizedBox(height: 8),
              const Center(
                child: CircularProgressIndicator(),
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
