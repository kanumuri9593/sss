import 'package:flutter/material.dart';
import '../models/nfc_tag_details.dart';

/// Screen displaying detailed technical information about an NFC tag
class NFCTagDetailsScreen extends StatelessWidget {
  final NFCTagDetails tagDetails;

  const NFCTagDetailsScreen({
    super.key,
    required this.tagDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.orange[700],
        ),
        title: const Text('Tag detail'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailRow(
            icon: Icons.tag,
            label: 'Tag type',
            value: tagDetails.tagType != null && tagDetails.tagModel != null
                ? '${tagDetails.tagType} : ${tagDetails.tagModel}'
                : tagDetails.tagType ?? tagDetails.tagModel ?? 'Unknown',
          ),
          if (tagDetails.technologiesAvailable != null)
            _buildDetailRow(
              icon: Icons.info_outline,
              label: 'Technologies available',
              value: tagDetails.technologiesAvailable!,
            ),
          if (tagDetails.serialNumber != null)
            _buildDetailRow(
              icon: Icons.vpn_key,
              label: 'Serial number',
              value: tagDetails.serialNumber!,
            ),
          if (tagDetails.atqa != null)
            _buildDetailRow(
              icon: Icons.label,
              label: 'ATQA',
              value: tagDetails.atqa!,
            ),
          if (tagDetails.sak != null)
            _buildDetailRow(
              icon: Icons.label_outline,
              label: 'SAK',
              value: tagDetails.sak!,
            ),
          _buildDetailRow(
            icon: Icons.lock_outline,
            label: 'Protected by password',
            value: tagDetails.protectedByPassword == true ? 'Yes' : 'No',
          ),
          if (tagDetails.memoryInformation != null)
            _buildDetailRow(
              icon: Icons.storage,
              label: 'Memory information',
              value: tagDetails.memoryInformation!,
            ),
          if (tagDetails.dataFormat != null)
            _buildDetailRow(
              icon: Icons.data_object,
              label: 'Data format',
              value: tagDetails.dataFormat!,
            ),
          _buildDetailRow(
            icon: Icons.edit,
            label: 'Writable',
            value: tagDetails.writable == true ? 'Yes' : 'No',
          ),
          if (tagDetails.scannedData != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.text_fields,
              label: 'Scanned Data',
              value: tagDetails.scannedData!,
              isLongText: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              icon,
              color: Colors.black87,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label :',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                isLongText
                    ? SelectableText(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

