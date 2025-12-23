import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../models/nfc_tag_data.dart';
import '../services/nfc_service.dart';
import 'nfc_simple_screen.dart';
import 'nfc_registration_screen.dart';
import 'nfc_detail_screen.dart';

/// POC Screen for testing NFC tag reading and registration features
class NFCPOCScreen extends StatefulWidget {
  const NFCPOCScreen({super.key});

  @override
  State<NFCPOCScreen> createState() => _NFCPOCScreenState();
}

class _NFCPOCScreenState extends State<NFCPOCScreen> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final FocusNode _dataFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _identifierFocusNode = FocusNode();

  String? _statusMessage;
  bool _isSuccess = false;
  bool _isNfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
    _dataController.text = 'Sample NFC Tag Data';
  }

  @override
  void dispose() {
    _dataController.dispose();
    _titleController.dispose();
    _identifierController.dispose();
    _dataFocusNode.dispose();
    _titleFocusNode.dispose();
    _identifierFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkNFCAvailability() async {
    final isAvailable = await NFCService.isNFCAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
    });
    
    // If not available, show more detailed message
    if (!isAvailable) {
      final availability = await NfcManager.instance.checkAvailability();
      debugPrint('NFC Availability: $availability');
    }
  }

  void _navigateToReader() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NFCSimpleScreen(),
      ),
    ).then((scannedData) {
      if (scannedData != null && scannedData is Map<String, dynamic>) {
        final data = scannedData['data'] as String?;
        if (data != null) {
          setState(() {
            _dataController.text = data;
          });
          _showMessage('Scanned data loaded', true);
        }
      }
    });
  }

  void _navigateToRegistration() {
    final data = _dataController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? null
        : _titleController.text.trim();
    final identifier = _identifierController.text.trim().isEmpty
        ? null
        : _identifierController.text.trim();

    if (data.isEmpty) {
      _showMessage('Please enter data first', false);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NFCRegistrationScreen(
          data: data,
          title: title,
          customIdentifier: identifier,
        ),
      ),
    ).then((success) {
      if (success == true) {
        _showMessage('NFC tag registered successfully', true);
      }
    });
  }

  void _viewRegisteredTags() {
    final tags = NFCService.getAllRegisteredTags();
    if (tags.isEmpty) {
      _showMessage('No registered NFC tags found', false);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registered NFC Tags'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return ListTile(
                leading: const Icon(Icons.nfc),
                title: Text(tag.category ?? 'Untitled Tag'),
                subtitle: Text(tag.data),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NFCDetailScreen(nfcId: tag.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, bool isSuccess) {
    setState(() {
      _statusMessage = message;
      _isSuccess = isSuccess;
    });

    // Clear message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NFC Availability Status
            if (!_isNfcAvailable)
              FutureBuilder<NfcAvailability>(
                future: NfcManager.instance.checkAvailability(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final availability = snapshot.data!;
                  String message;
                  Color bgColor;
                  Color borderColor;
                  IconData icon;
                  
                  if (availability == NfcAvailability.disabled) {
                    message = 'NFC is disabled. Please enable NFC in Settings > General > NFC.';
                    bgColor = Colors.orange[100]!;
                    borderColor = Colors.orange;
                    icon = Icons.nfc;
                  } else if (availability == NfcAvailability.unsupported) {
                    message = 'NFC is not supported on this device.';
                    bgColor = Colors.red[100]!;
                    borderColor = Colors.red;
                    icon = Icons.block;
                  } else {
                    message = 'NFC status: $availability';
                    bgColor = Colors.grey[100]!;
                    borderColor = Colors.grey;
                    icon = Icons.info;
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: borderColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(color: borderColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Title/Category input
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: const InputDecoration(
                labelText: 'Title/Category (Optional)',
                hintText: 'Enter a title or category',
                border: OutlineInputBorder(),
                helperText: 'This title will be associated with the NFC tag',
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_dataFocusNode);
              },
            ),
            const SizedBox(height: 16),

            // Data input
            TextField(
              controller: _dataController,
              focusNode: _dataFocusNode,
              decoration: const InputDecoration(
                labelText: 'NFC Tag Data',
                hintText: 'Enter data to encode',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_identifierFocusNode);
              },
            ),
            const SizedBox(height: 16),

            // Custom identifier input
            TextField(
              controller: _identifierController,
              focusNode: _identifierFocusNode,
              decoration: const InputDecoration(
                labelText: 'Custom Identifier (Optional)',
                hintText: 'Enter a letter or emoji',
                border: OutlineInputBorder(),
                helperText: 'Add a visual identifier for this tag',
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isNfcAvailable ? _navigateToReader : null,
                  icon: const Icon(Icons.nfc),
                  label: const Text('Read NFC Tag'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isNfcAvailable ? _navigateToRegistration : null,
                  icon: const Icon(Icons.edit),
                  label: const Text('Register NFC Tag'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _viewRegisteredTags,
                  icon: const Icon(Icons.list),
                  label: const Text('View Registered Tags'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status message
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green[900] : Colors.red[900],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Info section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NFC System Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('System ID: ${NFCTagData.systemId}'),
                    Text('Version: ${NFCTagData.version}'),
                    const SizedBox(height: 8),
                    const Text(
                      'All NFC tags registered by this system include a system identifier and deep link support.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

