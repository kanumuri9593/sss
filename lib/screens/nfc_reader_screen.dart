import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/src/nfc_manager_android/tags/ndef.dart' as android;
import 'package:nfc_manager/src/nfc_manager_ios/tags/ndef.dart' as ios;
import 'package:ndef_record/ndef_record.dart';
import '../services/nfc_service.dart';
import '../models/nfc_tag_data.dart';
import 'nfc_detail_screen.dart';

/// NFC Reader Screen for scanning NFC tags
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

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  Future<void> _checkNFCAvailability() async {
    final isAvailable = await NFCService.isNFCAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
    });
    if (isAvailable) {
      _startReading();
    }
  }

  Future<void> _startReading() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _scannedData = null;
      _tagId = null;
      _isVerified = false;
      _errorMessage = null;
    });

    try {
      final isAvailable = await NFCService.isNFCAvailable();
      if (!isAvailable) {
        setState(() {
          _errorMessage = 'NFC is not available on this device';
          _isProcessing = false;
        });
        return;
      }

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            final tagId = NFCService.extractTagId(tag);
            String? data;

            // Try to read NDEF records
            // Ndef is platform-specific
            android.NdefAndroid? ndefAndroid;
            ios.NdefIos? ndefIos;
            try {
              ndefAndroid = android.NdefAndroid.from(tag);
              if (ndefAndroid == null) {
                ndefIos = ios.NdefIos.from(tag);
              }
            } catch (e) {
              debugPrint('Error getting Ndef: $e');
            }
            
            if (ndefAndroid != null || ndefIos != null) {
              NdefMessage? ndefMessage;
              if (ndefAndroid != null) {
                ndefMessage = await ndefAndroid.getNdefMessage();
              } else if (ndefIos != null) {
                ndefMessage = ndefIos.cachedNdefMessage ?? await ndefIos.readNdef();
              }
              
              if (ndefMessage != null && ndefMessage.records.isNotEmpty) {
                final record = ndefMessage.records.first;
                if (record.typeNameFormat == TypeNameFormat.wellKnown) {
                  if (record.type.length >= 1 && record.type[0] == 0x55) {
                    // URI record (0x55 is the prefix code for URI)
                    final uriBytes = record.payload;
                    if (uriBytes.isNotEmpty) {
                      final uriString = String.fromCharCodes(uriBytes.skip(1));
                      data = uriString;
                    }
                  } else {
                    // Text record or other well-known type
                    data = String.fromCharCodes(record.payload);
                  }
                } else if (record.typeNameFormat == TypeNameFormat.absoluteUri) {
                  // Absolute URI
                  data = String.fromCharCodes(record.payload);
                } else {
                  // Other types - try to decode as string
                  data = String.fromCharCodes(record.payload);
                }
              }
            }

            if (mounted) {
              setState(() {
                _tagId = tagId;
                _scannedData = data;
                _isProcessing = false;
              });

              // Verify if NFC tag was created by this system
              if (data != null) {
                final isVerified = NFCService.verifySystemNFC(data);
                setState(() {
                  _isVerified = isVerified;
                });
              }

              await NfcManager.instance.stopSession();
            }
          } catch (e) {
            debugPrint('Error reading NFC tag: $e');
            if (mounted) {
              setState(() {
                _errorMessage = 'Error reading tag: $e';
                _isProcessing = false;
              });
              await NfcManager.instance.stopSession();
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Error starting NFC session: $e');
      setState(() {
        _errorMessage = 'Error starting NFC session: $e';
        _isProcessing = false;
      });
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
                    const Text(
                      'Hold your device near the NFC tag',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep the tag close until scanning completes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ] else if (_scannedData != null) ...[
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tag Read Successfully',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (_errorMessage != null) ...[
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (!_isNfcAvailable) ...[
                    Icon(
                      Icons.block,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'NFC Not Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This device does not support NFC',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.nfc,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to Scan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap "Start Reading" to begin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Scanned data display
          if (_scannedData != null)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Verification status
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _isVerified
                              ? Colors.green[100]
                              : Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isVerified
                                  ? Icons.verified
                                  : Icons.info_outline,
                              color: _isVerified
                                  ? Colors.green[900]
                                  : Colors.orange[900],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isVerified
                                    ? '✓ Verified - Created by SSS System'
                                    : '⚠ Not created by this system',
                                style: TextStyle(
                                  color: _isVerified
                                      ? Colors.green[900]
                                      : Colors.orange[900],
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

                      // Scanned data
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Scanned Data:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _scannedData!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _useScannedData,
                              icon: const Icon(Icons.check),
                              label: const Text('Use Data'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor:
                                    Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Instructions when no scan yet
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.nfc,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hold device near NFC tag',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Position the tag close to your device',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
            ),
        ],
      ),
    );
  }
}

