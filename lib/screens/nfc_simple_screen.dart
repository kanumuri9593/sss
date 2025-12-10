import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../models/nfc_tag_registration.dart';

/// Simple NFC Screen - Scan, Register, or Edit
class NFCSimpleScreen extends StatefulWidget {
  const NFCSimpleScreen({super.key});

  @override
  State<NFCSimpleScreen> createState() => _NFCSimpleScreenState();
}

class _NFCSimpleScreenState extends State<NFCSimpleScreen> {
  // State
  bool _isScanning = false;
  String? _tagId;
  NFCTagRegistration? _tagData;
  String? _errorMessage;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _checklistInputController = TextEditingController();
  List<String> _tags = [];
  List<String> _checklistItems = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    _checklistInputController.dispose();
    super.dispose();
  }

  Future<void> _scanTag() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _tagId = null;
      _tagData = null;
      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _tagInputController.clear();
      _checklistInputController.clear();
      _tags.clear();
      _checklistItems.clear();
    });

    try {
      final result = await NFCService.readNFCTag();

      if (!mounted) return;

      if (result == null || result.containsKey('error')) {
        setState(() {
          _errorMessage = result?['error'] ?? 'Failed to scan tag';
          _isScanning = false;
        });
        return;
      }

      final tagId = result['tagId'] as String?;
      final data = result['data'] as String?;
      final isEmpty = result['isEmpty'] as bool? ?? true;

      setState(() {
        _tagId = tagId;
        _isScanning = false;
      });

      // If tag has data, parse it
      if (!isEmpty && data != null) {
        try {
          final registration = NFCTagRegistration.fromJsonString(data);
          setState(() {
            _tagData = registration;
          });
        } catch (e) {
          // Not in our format, just show raw data
          setState(() {
            _tagData = NFCTagRegistration(
              title: 'Unknown Tag',
              tags: [],
              description: data,
              checklistItems: [],
              createdAt: DateTime.now(),
            );
          });
        }
      }
      // If empty, form will show automatically

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _registerOrUpdateTag() async {
    if (!_formKey.currentState!.validate()) return;

    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Title is required');
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      // Create registration
      final registration = NFCTagRegistration(
        title: _titleController.text.trim(),
        tags: _tags,
        description: _descriptionController.text.trim(),
        checklistItems: _checklistItems,
        createdAt: _tagData?.createdAt ?? DateTime.now(),
        lastModified: _tagData != null ? DateTime.now() : null,
      );

      final dataToWrite = registration.toJsonString();

      // Write to tag
      final result = await NFCService.writeNFCTag(
        data: dataToWrite,
        tagId: _tagId,
      );

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tagData == null ? 'Tag registered successfully!' : 'Tag updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Rescan to show updated data
        _scanTag();
      } else {
        final error = result['error'] as String? ?? 'Unknown error';
        setState(() {
          _errorMessage = 'Write failed: $error';
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isScanning = false;
        });
      }
    }
  }

  void _editTag() {
    if (_tagData == null) return;

    setState(() {
      _titleController.text = _tagData!.title;
      _descriptionController.text = _tagData!.description;
      _tags = List.from(_tagData!.tags);
      _checklistItems = List.from(_tagData!.checklistItems);
      _tagData = null; // Clear to show form
    });
  }

  void _addTag() {
    final tag = _tagInputController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    }
  }

  void _addChecklistItem() {
    final item = _checklistInputController.text.trim();
    if (item.isNotEmpty) {
      setState(() {
        _checklistItems.add(item);
        _checklistInputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Tag Manager'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scan Button (always visible)
            if (_tagData == null)
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanTag,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.nfc, size: 32),
                label: Text(
                  _isScanning ? 'Scanning...' : 'Scan NFC Tag',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(24),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Show Tag Data (if scanned and has data)
            if (_tagData != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Tag Registered',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _editTag,
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Title
                      Text(
                        _tagData!.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      if (_tagData!.tags.isNotEmpty) ...[
                        const Text(
                          'Tags:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tagData!.tags.map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.blue[100],
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description
                      if (_tagData!.description.isNotEmpty) ...[
                        const Text(
                          'Description:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_tagData!.description),
                        const SizedBox(height: 16),
                      ],

                      // Checklist
                      if (_tagData!.checklistItems.isNotEmpty) ...[
                        const Text(
                          'Checklist:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._tagData!.checklistItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_box_outline_blank, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        )),
                      ],

                      const SizedBox(height: 16),

                      // Scan Again Button
                      OutlinedButton.icon(
                        onPressed: _scanTag,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Another Tag'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Show Registration Form (if scanned but empty)
            if (_tagId != null && _tagData == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assignment, color: Colors.blue, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'Register This Tag',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below and tap "Save to Tag"',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title *',
                                hintText: 'e.g., Storage Box A',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Title is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Tags
                            const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _tagInputController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add tag',
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) => _addTag(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _addTag,
                                  icon: const Icon(Icons.add_circle),
                                ),
                              ],
                            ),
                            if (_tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _tags.map((tag) => Chip(
                                  label: Text(tag),
                                  onDeleted: () => setState(() => _tags.remove(tag)),
                                )).toList(),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText: 'What\'s in this container?',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),

                            // Checklist
                            const Text('Checklist:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _checklistInputController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add item',
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) => _addChecklistItem(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _addChecklistItem,
                                  icon: const Icon(Icons.add_circle),
                                ),
                              ],
                            ),
                            if (_checklistItems.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ..._checklistItems.asMap().entries.map((entry) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.check_box_outline_blank),
                                title: Text(entry.value),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => setState(() => _checklistItems.removeAt(entry.key)),
                                ),
                              )),
                            ],
                            const SizedBox(height: 24),

                            // Save Button
                            ElevatedButton.icon(
                              onPressed: _isScanning ? null : _registerOrUpdateTag,
                              icon: const Icon(Icons.save),
                              label: const Text('Save to Tag'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Instructions (when nothing scanned yet)
            if (_tagId == null && _tagData == null && !_isScanning) ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.blue[700]),
                      const SizedBox(height: 16),
                      Text(
                        'How to use:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Tap "Scan NFC Tag" button\n'
                        '2. Hold the back of your iPhone near the tag\n'
                        '3. If empty: Fill in the form and save\n'
                        '4. If registered: View and edit the data',
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
