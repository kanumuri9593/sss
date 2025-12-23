import 'package:flutter/material.dart';
import '../models/nfc_tag_data.dart';
import '../services/nfc_service.dart';

/// NFC Detail Screen displayed when opening an NFC tag via deep link
class NFCDetailScreen extends StatelessWidget {
  final String nfcId;

  const NFCDetailScreen({
    super.key,
    required this.nfcId,
  });

  @override
  Widget build(BuildContext context) {
    // Look up NFC data by ID
    final nfcData = NFCService.getNFCTagDataById(nfcId);

    if (nfcData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('NFC Tag Not Found'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'NFC Tag Not Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: $nfcId',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(nfcData.category ?? 'NFC Tag Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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
                      _buildMetadataRow(
                        'Identifier',
                        nfcData.customIdentifier!,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
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

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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










