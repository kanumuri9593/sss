import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../models/nfc_tag_data.dart';
import '../models/nfc_tag_registration.dart';
import 'nfc_detail_screen.dart';
import 'nfc_tag_register_screen.dart';

/// NFC Reader Screen for scanning NFC tags
/// Rebuilt for iOS and Android compatibility
class NFCReaderScreen extends StatefulWidget {
  const NFCReaderScreen({super.key});

  @override
  State<NFCReaderScreen> createState() => _NFCReaderScreenState();
}

class _NFCReaderScreenState extends State<NFCReaderScreen> {
  String? _scannedData;
  String? _tagId;
  bool _isVerified = false;
  bool _isProcessing = false;
  bool _isNfcAvailable = false;
  String? _errorMessage;
  String _statusMessage = 'Ready';
  NFCTagRegistration? _registrationData;

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  @override
  void dispose() {
    NFCService.stopSession();
    super.dispose();
  }

  Future<void> _checkNFCAvailability() async {
    final isAvailable = await NFCService.isNFCAvailable();
    final status = await NFCService.getNFCAvailabilityStatus();

    if (mounted) {
      setState(() {
        _isNfcAvailable = isAvailable;
        if (!isAvailable) {
          if (status.toString().contains('disabled')) {
            _errorMessage = 'NFC is disabled. Please enable NFC in Settings.';
          } else {
            _errorMessage = 'NFC is not supported on this device.';
          }
        }
      });
    }
  }

  Future<void> _startReading() async {
    if (_isProcessing) {
      debugPrint('[UI] Already processing, ignoring request');
      return;
    }

    debugPrint('[UI] ========== Start Reading NFC ==========');

    setState(() {
      _isProcessing = true;
      _scannedData = null;
      _tagId = null;
      _isVerified = false;
      _errorMessage = null;
      _statusMessage = 'Starting NFC session...';
    });

    try {
      // Use the new simplified readNFCTag API
      final result = await NFCService.readNFCTag();

      debugPrint('[UI] Read result: $result');

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _errorMessage = 'Failed to read NFC tag';
          _isProcessing = false;
          _statusMessage = 'Failed';
        });
        return;
      }

      // Check for errors
      if (result.containsKey('error')) {
        setState(() {
          _errorMessage = result['error'] as String;
          _isProcessing = false;
          _statusMessage = 'Error';
        });
        return;
      }

      // Extract data from result
      final tagId = result['tagId'] as String?;
      final data = result['data'] as String?;
      final isEmpty = result['isEmpty'] as bool? ?? false;

      debugPrint('[UI] Tag ID: $tagId, Data: ${data ?? "empty"}, isEmpty: $isEmpty');

      // Try to parse as registration data
      NFCTagRegistration? regData;
      if (data != null) {
        try {
          regData = NFCTagRegistration.fromJsonString(data);
        } catch (e) {
          debugPrint('[UI] Not a registration format: $e');
        }
      }

      // Verify if NFC tag was created by this system
      bool isVerified = false;
      if (data != null) {
        isVerified = NFCService.verifySystemNFC(data) ||
            NFCTagRegistration.isAppFormat(data);
      }

      setState(() {
        _tagId = tagId;
        _scannedData = data;
        _registrationData = regData;
        _isVerified = isVerified;
        _isProcessing = false;
        _statusMessage = data == null ? 'Empty tag detected' : 'Tag read successfully';
        _errorMessage = null;
      });

    } catch (e, stackTrace) {
      debugPrint('[UI] Error in read operation: $e');
      debugPrint('[UI] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isProcessing = false;
          _statusMessage = 'Error';
        });
      }
    }
  }

  void _resumeReading() {
    _startReading();
  }

  void _useScannedData() {
    if (_scannedData != null) {
      // Check if it's a deep link
      if (NFCTagData.isSystemDeepLink(_scannedData!)) {
        final id = NFCTagData.extractIdFromDeepLink(_scannedData!);
        if (id != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NFCDetailScreen(nfcId: id),
            ),
          );
          return;
        }
      }

      // Return scanned data to previous screen
      Navigator.pop(context, {'data': _scannedData, 'tagId': _tagId});
    }
  }

  Future<void> _writeTagData(String data) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = 'Writing to tag...';
    });

    try {
      final result = await NFCService.writeNFCTag(data: data, tagId: _tagId);

      debugPrint('[UI] Write result: $result');

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tag written successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Re-read the tag to confirm
        _resumeReading();
      } else {
        final error = result['error'] as String? ?? 'Unknown error';
        setState(() {
          _errorMessage = 'Write failed: $error';
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('[UI] Error writing tag: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Write error: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read NFC Tag'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // NFC reader view
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isProcessing ? Colors.blue : Colors.grey,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Icon(Icons.nfc, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Hold your device near the NFC tag',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Position the BACK of your phone close to the tag and keep it steady',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else if (_tagId != null || _scannedData != null) ...[
                    Icon(
                      _scannedData != null ? Icons.check_circle : Icons.info_outline,
                      size: 64,
                      color: _scannedData != null ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _scannedData != null
                          ? 'Tag Read Successfully'
                          : 'Tag Detected (Empty)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_scannedData == null && _tagId != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '✓ NFC Tag Detected!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This tag is blank. Tap "Register Tag" to write data to it.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else if (_errorMessage != null) ...[
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else if (!_isNfcAvailable) ...[
                    const Icon(Icons.block, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'NFC Not Available',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage ?? 'This device does not support NFC',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.nfc, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to Scan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap "Start Reading" to begin',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Scanned data display
          if (_tagId != null || _scannedData != null)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Verification status
                      if (_scannedData != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _isVerified ? Colors.green[100] : Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isVerified ? Colors.green : Colors.orange,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isVerified ? Icons.verified : Icons.info_outline,
                                color: _isVerified ? Colors.green[900] : Colors.orange[900],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isVerified
                                      ? '✓ Verified - Created by SSS System'
                                      : '⚠ Not created by this system',
                                  style: TextStyle(
                                    color: _isVerified ? Colors.green[900] : Colors.orange[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Tag ID
                      if (_tagId != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tag ID:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  _tagId!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Scanned data or empty message
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _scannedData != null ? 'Scanned Data:' : 'Tag Status:',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_scannedData != null)
                                SelectableText(
                                  _scannedData!,
                                  style: const TextStyle(fontSize: 12),
                                )
                              else
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'This NFC tag is empty.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap "Register Tag" to write data.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      if (_scannedData == null && _tagId != null)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NFCTagRegisterScreen(
                                  isEdit: false,
                                ),
                              ),
                            );
                            if (result is String && mounted) {
                              _writeTagData(result);
                            }
                          },
                          icon: const Icon(Icons.app_registration),
                          label: const Text('Register Tag'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                        ),

                      if (_scannedData != null) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NFCTagRegisterScreen(
                                  existingData: _registrationData,
                                  tagId: _tagId,
                                  isEdit: true,
                                ),
                              ),
                            );
                            if (result is String && mounted) {
                              _writeTagData(result);
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Tag'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear Tag?'),
                                content: const Text(
                                  'This will delete all data from the tag. Continue?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              _writeTagData('');
                            }
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Clear Tag'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _resumeReading,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Read Again'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          if (_scannedData != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _useScannedData,
                                icon: const Icon(Icons.check),
                                label: const Text('Use Data'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.nfc, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to scan NFC tags',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    if (!_isProcessing && _isNfcAvailable)
                      ElevatedButton.icon(
                        onPressed: _startReading,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Reading'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
