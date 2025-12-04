import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:ndef_record/ndef_record.dart';
import '../services/nfc_service.dart';
import '../models/nfc_tag_data.dart';
import '../models/nfc_tag_details.dart';
import '../models/nfc_tag_registration.dart';
import 'nfc_detail_screen.dart';
import 'nfc_tag_details_screen.dart';
import 'nfc_tag_register_screen.dart';

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
  NFCTagDetails? _tagDetails;
  String _statusMessage = 'Ready';
  NFCTagRegistration? _registrationData;

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  @override
  void dispose() {
    // Ensure any lingering NFC session is closed when leaving the screen
    NFCService.stopExistingSession(reason: 'reader_screen_dispose');
    super.dispose();
  }

  Future<void> _checkNFCAvailability() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      debugPrint('NFC Availability: $availability');

      final isAvailable = availability == NfcAvailability.enabled;
      setState(() {
        _isNfcAvailable = isAvailable;
        if (!isAvailable) {
          if (availability == NfcAvailability.disabled) {
            _errorMessage = 'NFC is disabled. Please enable NFC in Settings.';
          } else if (availability == NfcAvailability.unsupported) {
            _errorMessage = 'NFC is not supported on this device.';
          }
        }
      });
      // Don't auto-start reading on init - wait for user to tap button
      // This prevents iOS session issues and gives user control
    } catch (e) {
      debugPrint('Error checking NFC availability: $e');
      setState(() {
        _isNfcAvailable = false;
        _errorMessage = 'Error checking NFC: $e';
      });
    }
  }

  Future<void> _startReading() async {
    if (_isProcessing) {
      debugPrint('Already processing, ignoring request');
      return;
    }

    debugPrint('=== START READING CALLED ===');
    setState(() {
      _isProcessing = true;
      _scannedData = null;
      _tagId = null;
      _isVerified = false;
      _errorMessage = null;
      _tagDetails = null;
      _statusMessage = 'Initializing...';
    });

    try {
      await NFCService.stopExistingSession(reason: 'reader_start');

      debugPrint('Checking NFC availability...');
      final availability = await NfcManager.instance.checkAvailability();
      debugPrint('NFC Availability result: $availability');

      final isAvailable = availability == NfcAvailability.enabled;
      if (!isAvailable) {
        String message;
        if (availability == NfcAvailability.disabled) {
          message = 'NFC is disabled. Please enable NFC in Settings.';
        } else {
          message = 'NFC is not available on this device';
        }
        debugPrint('NFC not available: $message');
        setState(() {
          _errorMessage = message;
          _isProcessing = false;
        });
        return;
      }

      debugPrint('✓ NFC is available and enabled');
      debugPrint('Starting NFC session with polling options: ISO14443, ISO15693');

      setState(() {
        _statusMessage = 'NFC Session Active - Waiting for tag...';
      });

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,  // NTAG 213 uses ISO14443 Type A
          NfcPollingOption.iso15693,
        },
        alertMessageIos: 'Hold your iPhone near the NFC tag',
        invalidateAfterFirstReadIos: true,
        onSessionErrorIos: (error) {
          debugPrint('❌ NFC Session Error (iOS): ${error.message}');
          debugPrint('   Error details: ${error.toString()}');
          
          // Treat "empty tag" (403) as a normal empty read to avoid surfacing an error banner.
          // Check both the error object itself and the message string
          final emptyTag = NFCService.isEmptyNdefError(error) || 
                          NFCService.isEmptyNdefError(error.message);
          
          if (emptyTag) {
            debugPrint('✓ iOS detected empty/blank NFC tag (error 403 - this is normal)');
            if (mounted) {
              setState(() {
                _statusMessage = 'Empty tag detected';
                _isProcessing = false;
                _errorMessage = null;
                _tagId = 'detected';  // Mark that a tag was detected
              });
            }
            return;
          }
          
          // Real error (not just empty tag)
          debugPrint('⚠ Real NFC error (not empty tag): ${error.message}');
          if (mounted) {
            setState(() {
              _errorMessage = 'NFC Error: ${error.message}';
              _isProcessing = false;
            });
          }
        },
        onDiscovered: (NfcTag tag) async {
          debugPrint('✓ onDiscovered callback triggered!');
          bool sessionStopped = false;

          if (mounted) {
            setState(() {
              _statusMessage = 'Tag detected! Reading...';
            });
          }

          try {
            debugPrint('========================================');
            debugPrint('NFC TAG DISCOVERED!');
            debugPrint('========================================');
            final tagId = NFCService.extractTagId(tag);
            debugPrint('Tag ID: $tagId');
            String? data;

            // Try to read NDEF records
            NdefAndroid? ndefAndroid;
            NdefIos? ndefIos;
            try {
              if (defaultTargetPlatform == TargetPlatform.android) {
                ndefAndroid = NdefAndroid.from(tag);
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                ndefIos = NdefIos.from(tag);
              }
            } catch (e) {
              debugPrint('Error getting NDEF handler: $e');
            }

            if (ndefAndroid != null || ndefIos != null) {
              NdefMessage? ndefMessage;
              try {
                if (ndefAndroid != null) {
                  ndefMessage = ndefAndroid.cachedNdefMessage ?? await ndefAndroid.getNdefMessage();
                } else if (ndefIos != null) {
                  ndefMessage = ndefIos.cachedNdefMessage ?? await ndefIos.readNdef();
                }
                debugPrint('NDEF message: ${ndefMessage != null ? "found (${ndefMessage.records.length} records)" : "null"}');
              } catch (e) {
                debugPrint('Error reading NDEF message: $e');

                // Check if this is the "empty NDEF" error (iOS error 403)
                // This is a normal case for empty/unformatted tags
                if (NFCService.isEmptyNdefError(e)) {
                  debugPrint('Tag is empty/unformatted (no NDEF data) - this is normal');
                  ndefMessage = null;
                } else {
                  debugPrint('Unexpected error reading NDEF: $e');
                  ndefMessage = null;
                }
              }

              if (ndefMessage != null && ndefMessage.records.isNotEmpty) {
                final record = ndefMessage.records.first;
                debugPrint('Processing NDEF record - TNF: ${record.typeNameFormat}, Type: ${record.type}, Payload length: ${record.payload.length}');

                data = NFCService.decodeNdefRecord(record);
                debugPrint('Decoded NDEF data: ${data ?? "null"}');
              } else {
                debugPrint('Tag detected but has no NDEF data (empty tag)');
              }
            } else {
              debugPrint('Tag does not support NDEF format');
            }

            if (mounted) {
              // Extract detailed tag information
              final tagDetails = NFCService.extractTagDetails(tag, scannedData: data);

              // Try to parse as registration data
              NFCTagRegistration? regData;
              if (data != null) {
                try {
                  regData = NFCTagRegistration.fromJsonString(data);
                } catch (e) {
                  debugPrint('Not a registration format: $e');
                }
              }

              setState(() {
                _tagId = tagId;
                _scannedData = data;  // Can be null if tag is empty
                _tagDetails = tagDetails;
                _registrationData = regData;
                _isProcessing = false;
                _statusMessage = data == null ? 'Empty tag detected' : 'Tag read successfully';
                // Clear error message if tag was detected
                if (tagId != null && tagId != 'unknown') {
                  _errorMessage = null;
                }
              });

              // Verify if NFC tag was created by this system
              if (data != null) {
                final isVerified = NFCService.verifySystemNFC(data) ||
                                   NFCTagRegistration.isAppFormat(data);
                setState(() {
                  _isVerified = isVerified;
                });
              }

            }

            await NfcManager.instance.stopSession(
              alertMessageIos: 'Tag read successfully!',
            );
            sessionStopped = true;
          } catch (e, stackTrace) {
            debugPrint('Error reading NFC tag: $e');
            debugPrint('Stack trace: $stackTrace');
            
            // Try to extract tag ID even if there was an error
            String? extractedTagId;
            try {
              extractedTagId = NFCService.extractTagId(tag);
            } catch (_) {
              // Ignore errors extracting tag ID
            }
            
            // Check if this is an empty NDEF error (normal case)
            final isEmptyNdef = NFCService.isEmptyNdefError(e);
            
            if (!sessionStopped) {
              try {
                await NfcManager.instance.stopSession(
                  alertMessageIos: isEmptyNdef ? 'Empty tag detected' : 'Failed to read tag',
                );
                sessionStopped = true;
              } catch (stopError) {
                debugPrint('Error stopping session: $stopError');
              }
            }
            
            if (mounted) {
              if (isEmptyNdef) {
                // Empty tag is normal - show it as detected, not as an error
                debugPrint('✓ Empty tag detected (error 403) - this is normal');
                setState(() {
                  _tagId = extractedTagId ?? 'detected';
                  _scannedData = null;
                  _errorMessage = null;
                  _isProcessing = false;
                  _statusMessage = 'Empty tag detected';
                  // Extract tag details even for empty tags
                  try {
                    _tagDetails = NFCService.extractTagDetails(tag, scannedData: null);
                  } catch (_) {
                    // Ignore errors extracting details
                  }
                });
              } else {
                // Real error
                setState(() {
                  _errorMessage = 'Error reading tag: ${e.toString()}';
                  _isProcessing = false;
                  // Still try to show tag ID if we got it
                  if (extractedTagId != null && extractedTagId != 'unknown') {
                    _tagId = extractedTagId;
                  }
                });
              }
            }
          }
        },
      );
      debugPrint('✓ NFC session started successfully (waiting for tag)');
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting NFC session: $e');
      debugPrint('Stack trace: $stackTrace');
      await NFCService.stopExistingSession(reason: 'reader_start_error_cleanup');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error starting NFC session: $e';
          _isProcessing = false;
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
                    const SizedBox(height: 16),
                    const Text(
                      '📱 NFC Session Active',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
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
                      'Position the BACK of your iPhone close to the tag',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Keep it steady for 2-3 seconds',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
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
                      const SizedBox(height: 8),
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
                              '✓ NFC Tag Detected Successfully!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This tag is blank/empty. It\'s ready to have data written to it.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
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
          if (_tagId != null || _scannedData != null)
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
                      if (_scannedData != null)
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
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tag Status:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This NFC tag is empty and has no data.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap "Register Tag" button below to add title, tags, description, and checklist to this tag.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // EMPTY TAG - Show "Register Tag" button
                      if (_scannedData == null && _tagId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NFCTagRegisterScreen(
                                    isEdit: false,
                                  ),
                                ),
                              );
                              if (result == true && mounted) {
                                _resumeReading();
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
                        ),

                      // TAG WITH DATA - Show "Edit" and "Clear" buttons
                      if (_scannedData != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ElevatedButton.icon(
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
                              if (result == true && mounted) {
                                _resumeReading();
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
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Confirm before clearing
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Clear Tag?'),
                                  content: const Text(
                                    'This will permanently delete all data from the tag. Are you sure?',
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
                                      child: const Text('Clear Tag'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && mounted) {
                                setState(() {
                                  _isProcessing = true;
                                  _errorMessage = null;
                                });

                                try {
                                  // Write empty string to clear the tag
                                  final success = await NFCService.writeNFCTag(
                                    data: '',
                                    tagId: _tagId,
                                  );

                                  if (mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Tag cleared successfully!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _resumeReading();
                                    } else {
                                      setState(() {
                                        _errorMessage = 'Failed to clear tag';
                                        _isProcessing = false;
                                      });
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      _errorMessage = 'Error clearing tag: $e';
                                      _isProcessing = false;
                                    });
                                  }
                                }
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
                        ),
                      ],

                      // View Details button
                      if (_tagDetails != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NFCTagDetailsScreen(
                                    tagDetails: _tagDetails!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text('View Tag Details'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

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
                          if (_scannedData != null) ...[
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
