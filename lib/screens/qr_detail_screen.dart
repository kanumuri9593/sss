import 'package:flutter/material.dart';
import '../models/qr_data.dart';
import '../services/qr_service.dart';

/// QR Detail Screen displayed when opening a QR code via deep link
class QRDetailScreen extends StatelessWidget {
  final String qrId;

  const QRDetailScreen({
    super.key,
    required this.qrId,
  });

  @override
  Widget build(BuildContext context) {
    // Look up QR data by ID
    final qrData = QRService.getQRDataById(qrId);

    if (qrData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Code Not Found'),
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
                'QR Code Not Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: $qrId',
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
        title: Text(qrData.category ?? 'QR Code Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title/Category
            if (qrData.category != null && qrData.category!.isNotEmpty)
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
                        qrData.category!,
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

            // QR Code Data
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
                      qrData.data,
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
                    _buildMetadataRow('ID', qrData.id),
                    _buildMetadataRow('System ID', QRData.systemId),
                    _buildMetadataRow('Version', QRData.version),
                    _buildMetadataRow(
                      'Created',
                      DateTime.parse(qrData.timestamp)
                          .toString()
                          .substring(0, 19),
                    ),
                    if (qrData.customIdentifier != null)
                      _buildMetadataRow(
                        'Identifier',
                        qrData.customIdentifier!,
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

