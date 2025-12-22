import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:qr_flutter/qr_flutter.dart';
import '../models/container.dart' as models;
import '../services/container_service.dart';
import '../services/qr_service.dart';
import '../models/qr_data.dart';
import '../utils/file_utils.dart';
import '../services/image_recognition_service.dart';
import '../widgets/tag_editor_widget.dart';

/// Container Create/Edit Screen
/// 
/// Allows users to create or edit containers with photo, type selection,
/// and QR code generation. After creation, shows QR code below with edit/download options.
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
  final _qrRepaintKey = GlobalKey();

  models.ContainerType _selectedType = models.ContainerType.box;
  String? _photoPath;
  String? _selectedParentContainerId;
  bool _isLoading = false;
  bool _isProcessingImage = false;
  models.Container? _createdContainer;
  String? _qrDeepLink;
  String? _qrId;
  String _qrCustomIdentifier = '';
  Color _qrForegroundColor = Colors.black;
  Color _qrBackgroundColor = Colors.white;
  Color _qrIdentifierColor = Colors.black;

  List<models.Container> _availableParents = [];
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    // Initialize image recognition service
    ImageRecognitionService.initialize();
    
    if (widget.container != null) {
      _nameController.text = widget.container!.name;
      _descriptionController.text = widget.container!.description ?? '';
      _tags = List.from(widget.container!.tags);
      _selectedType = widget.container!.type;
      _photoPath = widget.container!.photoPath;
      _selectedParentContainerId = widget.container!.parentContainerId;
      _createdContainer = widget.container;
      _loadQRCode();
    }
    _loadAvailableParents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadQRCode() {
    if (_createdContainer == null) return;
    
    final container = _createdContainer!;
    if (container.qrCodeId != null) {
      _qrId = container.qrCodeId;
      final qrData = QRService.getQRDataById(_qrId!);
      if (qrData != null) {
        _qrDeepLink = qrData.buildDeepLink();
        _qrCustomIdentifier = qrData.customIdentifier ?? '';
      } else {
        // Generate new QR if not found
        _generateQRCode();
      }
    } else {
      _generateQRCode();
    }
  }

  void _generateQRCode() {
    if (_createdContainer == null) return;
    
    final container = _createdContainer!;
    final deepLink = container.buildDeepLink();
    
    // Generate QR code with deep link
    _qrDeepLink = QRService.generateDeepLink(
      data: deepLink,
      category: 'Container',
      customIdentifier: _qrCustomIdentifier.isEmpty ? null : _qrCustomIdentifier,
    );
    
    // Extract QR ID from deep link
    _qrId = QRData.extractIdFromDeepLink(_qrDeepLink!);
    if (_qrId != null) {
      ContainerService.linkQRCode(container.id, _qrId!);
    }
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
      setState(() {
        _isProcessingImage = true;
      });

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

          // Auto-generate tags from image
          try {
            final generatedTags = await ImageRecognitionService.processImage(savedPath);
            
            // Also add container type-based tags if not already present
            final containerTypeTags = ImageRecognitionService.generateTagsForContainer(_selectedType);
            
            // Merge tags (avoid duplicates)
            final allTags = <String>[];
            for (final tag in generatedTags) {
              if (!allTags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
                allTags.add(tag);
              }
            }
            for (final tag in containerTypeTags) {
              if (!allTags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
                allTags.add(tag);
              }
            }
            
            // Merge with existing tags
            final updatedTags = List<String>.from(_tags);
            for (final tag in allTags.take(5)) {
              if (!updatedTags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
                updatedTags.add(tag);
              }
            }

            setState(() {
              _tags = updatedTags;
            });
          } catch (e) {
            debugPrint('Error generating tags: $e');
            // Fallback: add container type tags
            final containerTypeTags = ImageRecognitionService.generateTagsForContainer(_selectedType);
            final updatedTags = List<String>.from(_tags);
            for (final tag in containerTypeTags) {
              if (!updatedTags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
                updatedTags.add(tag);
              }
            }
            setState(() {
              _tags = updatedTags;
            });
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

  Future<void> _saveContainer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
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
          tags: _tags,
        );
        await ContainerService.updateContainer(updated);
        _createdContainer = updated;
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
          tags: _tags,
        );
        await ContainerService.createContainer(container);
        _createdContainer = container;
        // Generate QR code after creation
        _generateQRCode();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Don't navigate away - stay to show QR code
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.container != null
                ? 'Container updated'
                : 'Container created! QR code generated below.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editQRCode() async {
    if (_createdContainer == null || _qrDeepLink == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _QREditDialog(
        customIdentifier: _qrCustomIdentifier,
        foregroundColor: _qrForegroundColor,
        backgroundColor: _qrBackgroundColor,
        identifierColor: _qrIdentifierColor,
      ),
    );

    if (result != null) {
      setState(() {
        _qrCustomIdentifier = result['customIdentifier'] ?? '';
        _qrForegroundColor = result['foregroundColor'] ?? Colors.black;
        _qrBackgroundColor = result['backgroundColor'] ?? Colors.white;
        _qrIdentifierColor = result['identifierColor'] ?? Colors.black;
      });
      // Regenerate QR with new settings
      _generateQRCode();
    }
  }

  Future<void> _downloadQRCode() async {
    if (_qrDeepLink == null || _createdContainer == null) return;

    try {
      // Capture QR code as image
      final imageBytes = await QRService.captureWidgetToImage(
        repaintBoundaryKey: _qrRepaintKey,
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture QR code')),
        );
        return;
      }

      // Export as PNG
      final fileName = 'container_${_createdContainer!.name}_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = await QRService.exportAsPNG(
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR code saved to $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading QR code: $e')),
        );
      }
    }
  }

  Future<void> _shareQRCode() async {
    if (_qrDeepLink == null || _createdContainer == null) return;

    try {
      // Capture QR code as image
      final imageBytes = await QRService.captureWidgetToImage(
        repaintBoundaryKey: _qrRepaintKey,
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture QR code')),
        );
        return;
      }

      // Save temporarily and share
      final fileName = 'container_${_createdContainer!.name}_qr.png';
      final filePath = await QRService.exportAsPNG(
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (filePath != null) {
        await QRService.shareFile(
          filePath: filePath,
          subject: 'QR Code for ${_createdContainer!.name}',
          text: 'QR Code for container: ${_createdContainer!.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing QR code: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.container != null;
    final showQR = _createdContainer != null && _qrDeepLink != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Container' : 'New Container'),
        actions: [
          if (showQR)
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () => Navigator.pop(context, true),
              tooltip: 'Done',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: showQR ? 32 : 16,
          ),
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
            // Tags Field with TagEditorWidget
            TagEditorWidget(
              tags: _tags,
              onTagsChanged: (tags) {
                setState(() {
                  _tags = tags;
                });
              },
              labelText: 'Tags',
              hintText: 'Comma-separated tags (e.g., winter, clothes, storage)',
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
            // QR Code Section (shown after creation)
            if (showQR) ...[
              const SizedBox(height: 32),
              Divider(thickness: 2),
              const SizedBox(height: 16),
              Text(
                'Container QR Code',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Scan this QR code to quickly access this container',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: RepaintBoundary(
                  key: _qrRepaintKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Make QR code responsive - use 80% of available width, max 250
                      final qrSize = (constraints.maxWidth * 0.8).clamp(200.0, 250.0);
                      return _buildQRWidget(size: qrSize);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _editQRCode,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit QR'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _downloadQRCode,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _shareQRCode,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRWidget({double size = 250}) {
    if (_qrDeepLink == null) return const SizedBox.shrink();
    
    // Use QrImageView directly with the existing deep link
    final qrWidget = QrImageView(
      data: _qrDeepLink!,
      size: size,
      backgroundColor: _qrBackgroundColor,
      foregroundColor: _qrForegroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    
    if (_qrCustomIdentifier.isEmpty) {
      return qrWidget;
    }
    
    // Add identifier overlay
    return Stack(
      alignment: Alignment.center,
      children: [
        qrWidget,
        Container(
          width: size * 0.2,
          height: size * 0.2,
          decoration: BoxDecoration(
            color: _qrBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _qrCustomIdentifier,
              style: TextStyle(
                fontSize: _qrCustomIdentifier.length > 1 ? size * 0.15 : size * 0.12,
                fontWeight: FontWeight.bold,
                color: _qrIdentifierColor,
              ),
            ),
          ),
        ),
      ],
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

/// Dialog for editing QR code appearance
class _QREditDialog extends StatefulWidget {
  final String customIdentifier;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color identifierColor;

  const _QREditDialog({
    required this.customIdentifier,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.identifierColor,
  });

  @override
  State<_QREditDialog> createState() => _QREditDialogState();
}

class _QREditDialogState extends State<_QREditDialog> {
  late TextEditingController _identifierController;
  late Color _foregroundColor;
  late Color _backgroundColor;
  late Color _identifierColor;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(text: widget.customIdentifier);
    _foregroundColor = widget.foregroundColor;
    _backgroundColor = widget.backgroundColor;
    _identifierColor = widget.identifierColor;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit QR Code'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Custom Identifier (Letter/Emoji)',
                hintText: 'e.g., A, 📦, etc.',
                helperText: 'Optional: Add a letter or emoji in the center',
              ),
              maxLength: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Foreground Color'),
              trailing: ColorPickerButton(
                color: _foregroundColor,
                onColorChanged: (color) {
                  setState(() {
                    _foregroundColor = color;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Background Color'),
              trailing: ColorPickerButton(
                color: _backgroundColor,
                onColorChanged: (color) {
                  setState(() {
                    _backgroundColor = color;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Identifier Color'),
              trailing: ColorPickerButton(
                color: _identifierColor,
                onColorChanged: (color) {
                  setState(() {
                    _identifierColor = color;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'customIdentifier': _identifierController.text,
              'foregroundColor': _foregroundColor,
              'backgroundColor': _backgroundColor,
              'identifierColor': _identifierColor,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Simple color picker button
class ColorPickerButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerButton({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _ColorPickerDialog(
            initialColor: color,
            onColorSelected: onColorChanged,
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 2),
        ),
      ),
    );
  }
}

/// Color picker dialog
class _ColorPickerDialog extends StatelessWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  final List<Color> _colors = const [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Color'),
      content: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: _colors.map((color) {
          return GestureDetector(
            onTap: () {
              onColorSelected(color);
              Navigator.pop(context);
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: initialColor == color ? Colors.black : Colors.grey,
                  width: initialColor == color ? 3 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
