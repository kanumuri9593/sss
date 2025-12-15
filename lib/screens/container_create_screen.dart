import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/container.dart' as models;
import '../services/container_service.dart';
import '../services/qr_service.dart';
import '../models/qr_data.dart';
import '../utils/file_utils.dart';
import 'nfc_write_screen.dart';

/// Container Create/Edit Screen
/// 
/// Allows users to create or edit containers with photo, type selection,
/// and QR/NFC linking.
class ContainerCreateScreen extends StatefulWidget {
  final models.Container? container;

  const ContainerCreateScreen({
    super.key,
    this.container,
  });

  @override
  State<ContainerCreateScreen> createState() => _ContainerCreateScreenState();
}

class _ContainerCreateScreenState extends State<ContainerCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  models.ContainerType _selectedType = models.ContainerType.box;
  String? _photoPath;
  String? _selectedParentContainerId;
  bool _isLoading = false;

  List<models.Container> _availableParents = [];

  @override
  void initState() {
    super.initState();
    if (widget.container != null) {
      _nameController.text = widget.container!.name;
      _descriptionController.text = widget.container!.description ?? '';
      _tagsController.text = widget.container!.tags.join(', ');
      _selectedType = widget.container!.type;
      _photoPath = widget.container!.photoPath;
      _selectedParentContainerId = widget.container!.parentContainerId;
    }
    _loadAvailableParents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _loadAvailableParents() {
    final allContainers = ContainerService.getAllContainers();
    // Exclude current container and its children from parent options
    if (widget.container != null) {
      final excludeIds = {widget.container!.id};
      // Add all nested containers recursively
      void addNested(String containerId) {
        final children = ContainerService.getChildContainers(containerId);
        for (var child in children) {
          excludeIds.add(child.id);
          addNested(child.id);
        }
      }
      addNested(widget.container!.id);
      _availableParents = allContainers
          .where((c) => !excludeIds.contains(c.id))
          .toList();
    } else {
      _availableParents = allContainers;
    }
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
        final fileName =
            'container_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedPath = await FileUtils.savePhoto(
          File(pickedFile.path),
          fileName,
        );
        if (savedPath != null) {
          setState(() {
            _photoPath = savedPath;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveContainer() async {
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

      if (widget.container != null) {
        // Update existing container
        final updated = widget.container!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          type: _selectedType,
          photoPath: _photoPath,
          parentContainerId: _selectedParentContainerId,
          tags: tags,
        );
        await ContainerService.updateContainer(updated);
      } else {
        // Create new container
        final container = models.Container.create(
          name: _nameController.text,
          type: _selectedType,
          photoPath: _photoPath,
          parentContainerId: _selectedParentContainerId,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          tags: tags,
        );
        await ContainerService.createContainer(container);
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

  Future<void> _linkQRCode() async {
    if (widget.container == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the container first'),
        ),
      );
      return;
    }

    final container = widget.container!;
    final deepLink = container.buildDeepLink();
    
    // Generate QR code with deep link
    final qrDeepLink = QRService.generateDeepLink(
      data: deepLink,
      category: 'Container',
    );
    
    // Extract QR ID from deep link
    final qrId = QRData.extractIdFromDeepLink(qrDeepLink);
    if (qrId != null) {
      final success = await ContainerService.linkQRCode(container.id, qrId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'QR code linked. You can generate it from QR tab.'
                : 'Failed to link QR code'),
          ),
        );
        if (success) {
          Navigator.pop(context, true); // Refresh container detail
        }
      }
    }
  }

  Future<void> _linkNFCTag() async {
    if (widget.container == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the container first'),
        ),
      );
      return;
    }

    final container = widget.container!;
    final deepLink = container.buildDeepLink();

    // Navigate to NFC write screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NFCWriteScreen(
          existingData: deepLink,
        ),
      ),
    ).then((result) async {
      // After writing NFC, link it to container
      // The NFC service will handle the data storage
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC tag written. Link it manually from container detail.'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.container != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Container' : 'New Container'),
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
                child: _photoPath != null &&
                        File(_photoPath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_photoPath!),
                          fit: BoxFit.cover,
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
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Container Name *',
                hintText: 'e.g., Winter Clothes Box',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a container name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Type Selector
            DropdownButtonFormField<models.ContainerType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Container Type *',
              ),
              items: models.ContainerType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Parent Container Selector (for nesting)
            DropdownButtonFormField<String>(
              initialValue: _selectedParentContainerId,
              decoration: const InputDecoration(
                labelText: 'Parent Container (Optional)',
                hintText: 'Select parent for nesting',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None (Root Container)'),
                ),
                ..._availableParents.map((container) {
                  return DropdownMenuItem(
                    value: container.id,
                    child: Text(container.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedParentContainerId = value;
                });
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
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'Comma-separated tags (e.g., winter, clothes, storage)',
                helperText: 'Separate tags with commas',
              ),
            ),
            const SizedBox(height: 24),
            // QR/NFC Linking (only for existing containers)
            if (isEditing) ...[
              Text(
                'Link QR Code or NFC Tag',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _linkQRCode,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Link QR'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _linkNFCTag,
                      icon: const Icon(Icons.nfc),
                      label: const Text('Link NFC'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveContainer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Container' : 'Create Container'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(models.ContainerType type) {
    switch (type) {
      case models.ContainerType.box:
        return 'Box';
      case models.ContainerType.bag:
        return 'Bag';
      case models.ContainerType.drawer:
        return 'Drawer';
    }
  }
}
