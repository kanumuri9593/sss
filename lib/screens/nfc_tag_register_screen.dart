import 'package:flutter/material.dart';
import '../models/nfc_tag_registration.dart';
import '../services/nfc_service.dart';

/// Screen for registering/editing NFC tag data
class NFCTagRegisterScreen extends StatefulWidget {
  final NFCTagRegistration? existingData;
  final String? tagId;
  final bool isEdit;

  const NFCTagRegisterScreen({
    super.key,
    this.existingData,
    this.tagId,
    this.isEdit = false,
  });

  @override
  State<NFCTagRegisterScreen> createState() => _NFCTagRegisterScreenState();
}

class _NFCTagRegisterScreenState extends State<NFCTagRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _checklistInputController = TextEditingController();

  List<String> _tags = [];
  List<String> _checklistItems = [];
  bool _isWriting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!.title;
      _descriptionController.text = widget.existingData!.description;
      _tags = List.from(widget.existingData!.tags);
      _checklistItems = List.from(widget.existingData!.checklistItems);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    _checklistInputController.dispose();
    super.dispose();
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

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
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

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
  }

  Future<void> _writeToTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Title is required';
      });
      return;
    }

    setState(() {
      _isWriting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Create registration object
      final registration = NFCTagRegistration(
        title: _titleController.text.trim(),
        tags: _tags,
        description: _descriptionController.text.trim(),
        checklistItems: _checklistItems,
        createdAt: widget.existingData?.createdAt ?? DateTime.now(),
        lastModified: widget.isEdit ? DateTime.now() : null,
      );

      // Convert to JSON string
      final dataToWrite = registration.toJsonString();
      debugPrint('Writing registration data to NFC tag: ${dataToWrite.length} characters');

      // Write to tag
      final result = await NFCService.writeNFCTag(
        data: dataToWrite,
        tagId: widget.tagId,
      );

      if (mounted) {
        final success = result['success'] as bool? ?? false;
        if (success) {
          setState(() {
            _successMessage = widget.isEdit
                ? 'Tag updated successfully!'
                : 'Tag registered successfully!';
            _isWriting = false;
          });

          // Wait a moment to show success message
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            // Return the data that was written
            Navigator.pop(context, dataToWrite);
          }
        } else {
          final errorMsg = result['error'] as String? ?? 'Unknown error';
          setState(() {
            _errorMessage = 'Failed to write to tag: $errorMsg';
            _isWriting = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error writing to NFC tag: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isWriting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Tag' : 'Register New Tag'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success/Error messages
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter item title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Tags
              const Text(
                'Tags/Labels',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tag (e.g., Storage, Kitchen)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addTag,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeTag(tag),
                    );
                  }).toList(),
                )
              else
                const Text(
                  'No tags added yet',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter item description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 16),

              // Checklist
              const Text(
                'Checklist Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _checklistInputController,
                      decoration: const InputDecoration(
                        hintText: 'Add checklist item',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_box),
                      ),
                      onSubmitted: (_) => _addChecklistItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addChecklistItem,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_checklistItems.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _checklistItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.check_box_outline_blank, size: 20),
                        title: Text(_checklistItems[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _removeChecklistItem(index),
                        ),
                        dense: true,
                      );
                    },
                  ),
                )
              else
                const Text(
                  'No checklist items added yet',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(height: 32),

              // Write button
              ElevatedButton.icon(
                onPressed: _isWriting ? null : _writeToTag,
                icon: _isWriting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.nfc),
                label: Text(
                  _isWriting
                      ? 'Writing to Tag...'
                      : widget.isEdit
                          ? 'Update Tag'
                          : 'Register Tag',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.isEdit ? Colors.blue[700] : Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Instructions
              if (_isWriting)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Hold your iPhone near the NFC tag',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep it steady for 2-3 seconds',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
