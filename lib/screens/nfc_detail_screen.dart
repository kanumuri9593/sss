import 'package:flutter/material.dart';
import '../models/nfc_tag_data.dart';
import '../services/nfc_service.dart';
import '../services/nfc_tag_storage_service.dart';
import 'container_detail_screen.dart';

/// NFC Detail Screen displayed when opening an NFC tag via deep link.
///
/// Checks both persistent storage (NFCTagStorageService) and in-memory
/// registry (NFCService) to resolve NFC tag data after app restarts.
class NFCDetailScreen extends StatefulWidget {
  final String nfcId;

  const NFCDetailScreen({
    super.key,
    required this.nfcId,
  });

  @override
  State<NFCDetailScreen> createState() => _NFCDetailScreenState();
}

class _NFCDetailScreenState extends State<NFCDetailScreen> {
  NFCTagData? _nfcData;
  NFCTagStoredRegistration? _storedTag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTagData();
  }

  Future<void> _loadTagData() async {
    // Initialize storage if needed
    await NFCTagStorageService.initialize();

    // Try persistent storage first (survives app restart)
    final storedTag = NFCTagStorageService.getTagById(widget.nfcId);
    if (storedTag != null) {
      if (mounted) {
        setState(() {
          _storedTag = storedTag;
          _isLoading = false;
        });
      }
      return;
    }

    // Fall back to in-memory registry
    final nfcData = NFCService.getNFCTagDataById(widget.nfcId);
    if (mounted) {
      setState(() {
        _nfcData = nfcData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('NFC Tag')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If found in persistent storage
    if (_storedTag != null) {
      return _buildStoredTagView(context, _storedTag!);
    }

    // If found in in-memory registry
    if (_nfcData != null) {
      return _buildNfcDataView(context, _nfcData!);
    }

    // Not found
    return _buildNotFoundView(context);
  }

  Widget _buildStoredTagView(BuildContext context, NFCTagStoredRegistration tag) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tag.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.nfc, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tag.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (tag.description.isNotEmpty)
                                Text(
                                  tag.description,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Container link
            if (tag.containerId != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: Text(tag.containerName ?? 'Linked Container'),
                  subtitle: const Text('Tap to view container'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContainerDetailScreen(
                          containerId: tag.containerId!,
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (tag.containerId != null) const SizedBox(height: 16),

            // Tags
            if (tag.tags.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: tag.tags.map((t) => Chip(label: Text(t))).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            if (tag.tags.isNotEmpty) const SizedBox(height: 16),

            // Metadata
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metadata',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetadataRow('Registration ID', tag.id),
                    _buildMetadataRow('Physical Tag ID', tag.tagId),
                    _buildMetadataRow('Status', tag.status.name),
                    _buildMetadataRow(
                      'Created',
                      tag.createdAt.toString().substring(0, 19),
                    ),
                    if (tag.lastModified != null)
                      _buildMetadataRow(
                        'Modified',
                        tag.lastModified.toString().substring(0, 19),
                      ),
                    _buildMetadataRow('Deep Link', tag.deepLink),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcDataView(BuildContext context, NFCTagData nfcData) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nfcData.category ?? 'NFC Tag Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title/Category
            if (nfcData.category != null && nfcData.category!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category/Title',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nfcData.category!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // NFC Tag Data
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      nfcData.data,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Metadata
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metadata',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetadataRow('ID', nfcData.id),
                    _buildMetadataRow('System ID', NFCTagData.systemId),
                    _buildMetadataRow('Version', NFCTagData.version),
                    _buildMetadataRow(
                      'Created',
                      DateTime.parse(nfcData.timestamp)
                          .toString()
                          .substring(0, 19),
                    ),
                    if (nfcData.tagId != null)
                      _buildMetadataRow('Tag ID', nfcData.tagId!),
                    if (nfcData.customIdentifier != null)
                      _buildMetadataRow('Identifier', nfcData.customIdentifier!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Tag Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'NFC Tag Not Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${widget.nfcId}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
