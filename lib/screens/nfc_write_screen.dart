import 'package:flutter/material.dart';
import '../services/nfc_service.dart';

/// Screen for writing/editing data to NFC tags
class NFCWriteScreen extends StatefulWidget {
  final String? existingData;
  final String? tagId;
  final bool isEdit;

  const NFCWriteScreen({
    super.key,
    this.existingData,
    this.tagId,
    this.isEdit = false,
  });

  @override
  State<NFCWriteScreen> createState() => _NFCWriteScreenState();
}

class _NFCWriteScreenState extends State<NFCWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isWriting = false;
  String? _errorMessage;
  String? _successMessage;
  String _selectedDataType = 'text'; // text, url, custom

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      // Try to parse existing data
      _parseExistingData(widget.existingData!);
    }
  }

  void _parseExistingData(String data) {
    // If it's a URL
    if (data.startsWith('http://') || data.startsWith('https://')) {
      _selectedDataType = 'url';
      _urlController.text = data;
    } else {
      _selectedDataType = 'text';
      _titleController.text = data;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _buildDataToWrite() {
    switch (_selectedDataType) {
      case 'url':
        return _urlController.text.trim();
      case 'text':
        final title = _titleController.text.trim();
        final description = _descriptionController.text.trim();
        if (description.isNotEmpty) {
          return '$title\n$description';
        }
        return title;
      case 'custom':
        return _titleController.text.trim();
      default:
        return _titleController.text.trim();
    }
  }

  Future<void> _writeToTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isWriting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final dataToWrite = _buildDataToWrite();
      debugPrint('Writing data to NFC tag: $dataToWrite');

      final result = await NFCService.writeNFCTag(
        data: dataToWrite,
        tagId: widget.tagId,
      );

      if (mounted) {
        final success = result['success'] as bool? ?? false;
        if (success) {
          setState(() {
            _successMessage = 'Data written successfully!';
            _isWriting = false;
          });

          // Wait a moment to show success message, then return
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          final errorMsg = result['error'] as String? ?? 'Unknown error';
          setState(() {
            _errorMessage = 'Failed to write data to tag: $errorMsg';
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
        title: Text(widget.isEdit ? 'Edit NFC Tag Data' : 'Write to NFC Tag'),
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

              // Info card
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fill in the details below, then tap "Write to Tag" and hold your phone near the NFC tag.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Data type selector
              const Text(
                'Data Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'text',
                    label: Text('Text'),
                    icon: Icon(Icons.text_fields),
                  ),
                  ButtonSegment(
                    value: 'url',
                    label: Text('URL'),
                    icon: Icon(Icons.link),
                  ),
                ],
                selected: {_selectedDataType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedDataType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // URL field (shown when URL type selected)
              if (_selectedDataType == 'url') ...[
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a URL';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'URL must start with http:// or https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Text fields (shown when text type selected)
              if (_selectedDataType == 'text') ...[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),
              ],

              // Category field (optional for all types)
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  hintText: 'e.g., Storage, Equipment, Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                maxLength: 50,
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
                          ? 'Update Tag Data'
                          : 'Write to Tag',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
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
                        'Position the back of your phone close to the tag and keep it steady for 2-3 seconds',
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
