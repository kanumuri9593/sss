import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/src/nfc_manager_android/tags/ndef.dart' as android;
import 'package:nfc_manager/src/nfc_manager_ios/tags/ndef.dart' as ios;
import 'package:ndef_record/ndef_record.dart';
import '../services/nfc_service.dart';
import '../models/nfc_tag_data.dart';
import 'nfc_detail_screen.dart';

/// NFC Registration Screen for writing data to NFC tags
class NFCRegistrationScreen extends StatefulWidget {
  final String data;
  final String? title;
  final String? customIdentifier;

  const NFCRegistrationScreen({
    super.key,
    required this.data,
    this.title,
    this.customIdentifier,
  });

  @override
  State<NFCRegistrationScreen> createState() => _NFCRegistrationScreenState();
}

class _NFCRegistrationScreenState extends State<NFCRegistrationScreen> {
  bool _isWriting = false;
  bool _isNfcAvailable = false;
  String? _statusMessage;
  bool _isSuccess = false;
  String? _errorMessage;
  Timer? _sessionTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  @override
  void dispose() {
    _sessionTimeoutTimer?.cancel();
    // Ensure session is stopped when widget is disposed
    NfcManager.instance.stopSession().catchError((e) {
      debugPrint('Error stopping NFC session on dispose: $e');
    });
    super.dispose();
  }

  Future<void> _checkNFCAvailability() async {
    final isAvailable = await NFCService.isNFCAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
    });
  }

  Future<void> _writeToTag() async {
    if (_isWriting) return;

    if (!mounted) return;

    setState(() {
      _isWriting = true;
      _statusMessage = null;
      _errorMessage = null;
      _isSuccess = false;
    });

    // Cancel any existing timeout timer
    _sessionTimeoutTimer?.cancel();

    try {
      await NFCService.stopSession();

      final isAvailable = await NFCService.isNFCAvailable();
      if (!isAvailable) {
        if (mounted) {
          setState(() {
            _errorMessage = 'NFC is not available on this device';
            _isWriting = false;
          });
        }
        return;
      }

      String? actualTagId;
      String? generatedId; // Store the ID from deep link generation to reuse

      // Generate deep link for the data (this creates and registers an entry)
      // We'll update it with the actual tagId after writing
      final deepLink = NFCService.generateDeepLink(
        data: widget.data,
        customIdentifier: widget.customIdentifier,
        category: widget.title,
      );
      
      // Extract the ID from the generated deep link
      generatedId = NFCTagData.extractIdFromDeepLink(deepLink);

      // Set up a timeout to stop the session if no tag is detected
      _sessionTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _isWriting) {
          NfcManager.instance.stopSession().then((_) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Timeout: No NFC tag detected. Please try again.';
                _isWriting = false;
              });
            }
          }).catchError((e) {
            debugPrint('Error stopping session on timeout: $e');
            if (mounted) {
              setState(() {
                _errorMessage = 'Timeout: No NFC tag detected. Please try again.';
                _isWriting = false;
              });
            }
          });
        }
      });

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          // Cancel timeout since tag was discovered
          _sessionTimeoutTimer?.cancel();
          
          bool sessionStopped = false;
          
          try {
            // Extract tag ID
            try {
              actualTagId = NFCService.extractTagId(tag);
            } catch (e) {
              debugPrint('Error extracting tag ID: $e');
              actualTagId = null;
            }

            // Check if tag supports NDEF
            // Ndef is platform-specific
            android.NdefAndroid? ndefAndroid;
            ios.NdefIos? ndefIos;
            try {
              if (defaultTargetPlatform == TargetPlatform.android) {
                ndefAndroid = android.NdefAndroid.from(tag);
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                ndefIos = ios.NdefIos.from(tag);
              }
            } catch (e) {
              debugPrint('Error getting Ndef: $e');
            }
            
            if (ndefAndroid == null && ndefIos == null) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Tag does not support NDEF';
                  _isWriting = false;
                });
              }
              await NfcManager.instance.stopSession();
              sessionStopped = true;
              return;
            }

            // Check if tag is writable (Android only)
            if (ndefAndroid != null && !ndefAndroid.isWritable) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Tag is not writable';
                  _isWriting = false;
                });
              }
              await NfcManager.instance.stopSession();
              sessionStopped = true;
              return;
            }

            // Create NDEF message with deep link
            // For URI records, type is [0x55] and payload must start with URI prefix byte
            // 0x00 = no prefix (absolute URI), 0x01 = http://www., 0x02 = https://www., etc.
            // Since we're writing a full URI (sss://...), we use 0x00 (no prefix)
            final uriBytes = deepLink.codeUnits;
            final payload = Uint8List(uriBytes.length + 1);
            payload[0] = 0x00; // URI prefix: 0x00 = no prefix (absolute URI)
            payload.setRange(1, payload.length, uriBytes);
            
            final ndefRecord = NdefRecord(
              typeNameFormat: TypeNameFormat.wellKnown,
              type: Uint8List.fromList([0x55]), // URI record type
              identifier: Uint8List(0),
              payload: payload,
            );

            final ndefMessage = NdefMessage(records: [ndefRecord]);

            // Write to tag with proper error handling
            try {
              if (ndefAndroid != null) {
                await ndefAndroid.writeNdefMessage(ndefMessage);
              } else if (ndefIos != null) {
                await ndefIos.writeNdef(ndefMessage);
              }
            } catch (writeError) {
              debugPrint('Error during NFC write operation: $writeError');
              if (mounted) {
                setState(() {
                  _errorMessage = 'Failed to write to tag: ${writeError.toString()}';
                  _isWriting = false;
                  _isSuccess = false;
                });
              }
              await NfcManager.instance.stopSession();
              sessionStopped = true;
              return;
            }

            // Update the existing registry entry with actual tag ID instead of creating a duplicate
            if (generatedId != null) {
              try {
                final existingData = NFCService.getNFCTagDataById(generatedId);
                if (existingData != null) {
                  // Update the existing entry with the actual tag ID
                  final updatedData = NFCTagData(
                    id: existingData.id,
                    data: existingData.data,
                    timestamp: existingData.timestamp,
                    tagId: actualTagId,
                    customIdentifier: existingData.customIdentifier,
                    category: existingData.category,
                  );
                  NFCService.registerNFCTagData(updatedData);
                }
              } catch (e) {
                debugPrint('Error updating registry: $e');
                // Don't fail the write operation if registry update fails
              }
            }

            if (mounted) {
              setState(() {
                _isWriting = false;
                _statusMessage = 'NFC tag registered successfully!';
                _isSuccess = true;
              });

              // Navigate to detail screen after a short delay
              if (generatedId != null) {
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NFCDetailScreen(nfcId: generatedId!),
                      ),
                    );
                  }
                });
              }
            }

            await NfcManager.instance.stopSession();
            sessionStopped = true;
          } catch (e, stackTrace) {
            debugPrint('Error writing NFC tag: $e');
            debugPrint('Stack trace: $stackTrace');
            
            if (!sessionStopped) {
              try {
                await NfcManager.instance.stopSession();
              } catch (stopError) {
                debugPrint('Error stopping session after exception: $stopError');
              }
            }
            
            if (mounted) {
              setState(() {
                _errorMessage = 'Error writing to tag: ${e.toString()}';
                _isWriting = false;
                _isSuccess = false;
              });
            }
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error starting NFC write session: $e');
      debugPrint('Stack trace: $stackTrace');
      
      _sessionTimeoutTimer?.cancel();
      
      // Ensure session is stopped
      try {
        await NfcManager.instance.stopSession();
      } catch (stopError) {
        debugPrint('Error stopping session after start error: $stopError');
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Error starting NFC session: ${e.toString()}';
          _isWriting = false;
          _isSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register NFC Tag'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Data preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data to Write:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.title != null) ...[
                      Text(
                        'Title: ${widget.title}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      widget.data,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // NFC writer view
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isWriting ? Colors.blue : Colors.grey,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isWriting) ...[
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
                      'Keep the tag close until writing completes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ] else if (_statusMessage != null && _isSuccess) ...[
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage!,
                      style: const TextStyle(
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
                      'Ready to Write',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap "Write to Tag" to begin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
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

            // Write button
            ElevatedButton.icon(
              onPressed: _isWriting || !_isNfcAvailable ? null : _writeToTag,
              icon: const Icon(Icons.edit),
              label: const Text('Write to Tag'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Tap "Write to Tag" button',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text(
                      '2. Hold your device near the NFC tag',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text(
                      '3. Keep the tag close until writing completes',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text(
                      '4. The tag will be registered in the system',
                      style: TextStyle(fontSize: 14),
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
