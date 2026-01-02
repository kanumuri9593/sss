import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:ndef_record/ndef_record.dart';
import '../models/nfc_tag_data.dart';
import '../models/nfc_tag_details.dart';

/// NFC Service for reading, writing, and managing NFC tags.
/// Optimized for iOS and Android compatibility.
class NFCService {
  /// In-memory registry of NFCTagData by id for this POC.
  static final Map<String, NFCTagData> _nfcRegistry = <String, NFCTagData>{};
  static final Map<String, String> _tagIdToDataId = <String, String>{};

  /// Track active NFC session state
  static bool _sessionActive = false;

  /// Check if an NFC session is currently active
  static bool get isSessionActive => _sessionActive;

  /// Check if NFC is available on the device.
  static Future<bool> isNFCAvailable() async {
    try {
      final status = await NfcManager.instance.checkAvailability();
      final result = status == NfcAvailability.enabled;
      debugPrint('[NFC] Device availability check: $result (status: $status)');
      return result;
    } catch (e) {
      debugPrint('[NFC] Error checking NFC availability: $e');
      return false;
    }
  }

  /// Get detailed NFC availability status
  static Future<NfcAvailability> getNFCAvailabilityStatus() async {
    try {
      final status = await NfcManager.instance.checkAvailability();
      debugPrint('[NFC] Availability status: $status');
      return status;
    } catch (e) {
      debugPrint('[NFC] Error getting NFC status: $e');
      return NfcAvailability.unsupported;
    }
  }

  /// Check if an error indicates an empty/unformatted NDEF tag.
  static bool isEmptyNdefError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // iOS error code 403 = empty NDEF tag (has NDEF format but no data)
    if (errorString.contains('403') || errorString.contains('code=403')) {
      return true;
    }

    // iOS error code 102 = tag not NDEF formatted at all
    if (errorString.contains('102') || errorString.contains('code=102')) {
      return true;
    }

    // iOS often says "session invalidated unexpectedly" for empty tags
    if (errorString.contains('session invalidated unexpectedly')) {
      return true;
    }

    // Check for "not formatted" patterns
    if (errorString.contains('not') && errorString.contains('formatted')) {
      return true;
    }

    // Check for empty message patterns
    if (errorString.contains('ndef')) {
      if ((errorString.contains('does not contain') && errorString.contains('message')) ||
          errorString.contains('no ndef') ||
          errorString.contains('empty')) {
        return true;
      }
    }

    return false;
  }

  /// Decode a single NDEF record to a readable string.
  static String? decodeNdefRecord(dynamic record) {
    try {
      // URI prefix map from NFC Forum specification
      const uriPrefixes = [
        '', 'http://www.', 'https://www.', 'http://', 'https://',
        'tel:', 'mailto:', 'ftp://anonymous:anonymous@', 'ftp://ftp.',
        'ftps://', 'sftp://', 'smb://', 'nfs://', 'ftp://', 'dav://',
        'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:', 'pop:',
        'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://', 'btgoep://',
        'tcpobex://', 'irdaobex://', 'file://', 'urn:epc:id:',
        'urn:epc:tag:', 'urn:epc:pat:', 'urn:epc:raw:', 'urn:epc:', 'urn:nfc:',
      ];

      // Get record properties safely
      final tnf = record.typeNameFormat;
      final type = record.type as List<int>?;
      final payload = record.payload as List<int>?;

      if (payload == null || payload.isEmpty) {
        debugPrint('[NFC] Empty payload in record');
        return null;
      }

      // Well-known type
      if (tnf == TypeNameFormat.wellKnown && type != null && type.isNotEmpty) {
        // URI record (0x55 = 'U')
        if (type[0] == 0x55) {
          final prefixCode = payload[0];
          final prefix = prefixCode < uriPrefixes.length ? uriPrefixes[prefixCode] : '';
          final uriBody = String.fromCharCodes(payload.skip(1));
          final fullUri = '$prefix$uriBody';
          debugPrint('[NFC] Decoded URI: $fullUri');
          return fullUri;
        }

        // Text record (0x54 = 'T')
        if (type[0] == 0x54) {
          final statusByte = payload[0];
          final languageCodeLength = statusByte & 0x3F;
          final textBytes = payload.skip(1 + languageCodeLength);
          final text = String.fromCharCodes(textBytes);
          debugPrint('[NFC] Decoded text: $text');
          return text;
        }
      }

      // Try to decode as string
      try {
        final decoded = String.fromCharCodes(payload);
        debugPrint('[NFC] Decoded as raw string: $decoded');
        return decoded;
      } catch (e) {
        debugPrint('[NFC] Failed to decode payload: $e');
        return null;
      }
    } catch (e) {
      debugPrint('[NFC] Error decoding record: $e');
      return null;
    }
  }

  /// Stop any existing NFC session safely
  static Future<void> stopSession({String? alertMessage}) async {
    try {
      // Always try to stop, even if we think there's no active session
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await NfcManager.instance.stopSession(
          alertMessageIos: alertMessage,
        );
      } else {
        await NfcManager.instance.stopSession();
      }
      debugPrint('[NFC] Session stopped successfully');
    } catch (e) {
      debugPrint('[NFC] Error stopping session (may already be stopped): $e');
    } finally {
      _sessionActive = false;
    }
  }

  /// Extract tag ID from NFC tag data
  static String? extractTagId(NfcTag tag) {
    try {
      // ignore: invalid_use_of_protected_member
      final tagData = tag.data;

      if (tagData is! Map) {
        debugPrint('[NFC] Tag data is not a Map');
        return null;
      }

      // Try different tag technologies
      final technologies = ['nfca', 'nfcb', 'nfcf', 'nfcv', 'iso15693', 'mifareClassic', 'mifareUltralight'];

      for (final tech in technologies) {
        final techData = tagData[tech];
        if (techData is Map) {
          final identifier = techData['identifier'] ?? techData['id'];
          if (identifier != null && identifier is List) {
            final tagId = identifier
                .map((e) => (e as int).toRadixString(16).padLeft(2, '0').toUpperCase())
                .join(':');
            debugPrint('[NFC] Extracted tag ID ($tech): $tagId');
            return tagId;
          }
        }
      }

      debugPrint('[NFC] Could not extract tag ID from any technology');
      return null;
    } catch (e) {
      debugPrint('[NFC] Error extracting tag ID: $e');
      return null;
    }
  }

  /// Read NFC tag - iOS and Android compatible
  static Future<Map<String, dynamic>?> readNFCTag() async {
    debugPrint('[NFC] ========== Starting NFC Read Session ==========');

    try {
      // Stop any existing session first
      await stopSession();
      await Future.delayed(const Duration(milliseconds: 500));

      // Check availability
      final isAvailable = await isNFCAvailable();
      if (!isAvailable) {
        debugPrint('[NFC] NFC is not available on this device');
        return {'error': 'NFC not available'};
      }

      // Check detailed status
      final status = await getNFCAvailabilityStatus();
      if (status != NfcAvailability.enabled) {
        debugPrint('[NFC] NFC status: $status (not enabled)');
        return {'error': 'NFC is not enabled. Please enable NFC in Settings.'};
      }

      debugPrint('[NFC] NFC is available and enabled');

      // Use Completer instead of while loop to avoid blocking
      final completer = Completer<Map<String, dynamic>>();

      // Start NFC session
      _sessionActive = true;

      debugPrint('[NFC] Starting session with simplified polling...');

      await NfcManager.instance.startSession(
        // Use just iso14443 - most common for NTAG tags
        pollingOptions: {
          NfcPollingOption.iso14443,
        },
        // iOS specific settings
        alertMessageIos: 'Hold your iPhone near the NFC tag',
        invalidateAfterFirstReadIos: true,

        // Error handler for iOS
        onSessionErrorIos: (error) {
          debugPrint('[NFC][iOS] Session error: ${error.message}');

          if (isEmptyNdefError(error) || isEmptyNdefError(error.message)) {
            debugPrint('[NFC][iOS] Detected empty tag (this is normal)');
            if (!completer.isCompleted) {
              completer.complete({
                'isEmpty': true,
                'tagId': null,
                'data': null,
                'message': 'Empty tag detected',
              });
            }
          } else {
            debugPrint('[NFC][iOS] Real error: ${error.message}');
            if (!completer.isCompleted) {
              completer.complete({
                'error': 'NFC Error: ${error.message}',
              });
            }
          }

          _sessionActive = false;
        },

        // Tag discovered handler
        onDiscovered: (NfcTag tag) async {
          debugPrint('[NFC] ========================================');
          debugPrint('[NFC] ✓✓✓ TAG DISCOVERED CALLBACK FIRED! ✓✓✓');
          debugPrint('[NFC] ========================================');

          try {
            // Extract tag ID
            final tagId = extractTagId(tag);
            debugPrint('[NFC] Tag ID: ${tagId ?? "unknown"}');

            // Try to read NDEF data
            String? ndefData;
            bool isEmpty = false;

            try {
              // Get NDEF handler based on platform
              if (defaultTargetPlatform == TargetPlatform.iOS) {
                final ndef = NdefIos.from(tag);
                if (ndef != null) {
                  debugPrint('[NFC][iOS] NDEF handler obtained');

                  // Try cached message first
                  var ndefMessage = ndef.cachedNdefMessage;

                  // If no cached message, read from tag
                  if (ndefMessage == null) {
                    debugPrint('[NFC][iOS] Reading NDEF from tag...');
                    try {
                      ndefMessage = await ndef.readNdef();
                    } catch (e) {
                      if (isEmptyNdefError(e)) {
                        debugPrint('[NFC][iOS] Tag is empty (no NDEF data)');
                        isEmpty = true;
                      } else {
                        debugPrint('[NFC][iOS] Error reading NDEF: $e');
                      }
                    }
                  }

                  if (ndefMessage != null && ndefMessage.records.isNotEmpty) {
                    debugPrint('[NFC][iOS] Found ${ndefMessage.records.length} NDEF records');
                    ndefData = decodeNdefRecord(ndefMessage.records.first);
                  } else {
                    isEmpty = true;
                  }
                }
              } else if (defaultTargetPlatform == TargetPlatform.android) {
                final ndef = NdefAndroid.from(tag);
                if (ndef != null) {
                  debugPrint('[NFC][Android] NDEF handler obtained');

                  final ndefMessage = await ndef.getNdefMessage();
                  if (ndefMessage != null && ndefMessage.records.isNotEmpty) {
                    debugPrint('[NFC][Android] Found ${ndefMessage.records.length} NDEF records');
                    ndefData = decodeNdefRecord(ndefMessage.records.first);
                  } else {
                    isEmpty = true;
                  }
                } else {
                  debugPrint('[NFC][Android] Tag does not support NDEF');
                  isEmpty = true;
                }
              }
            } catch (e) {
              debugPrint('[NFC] Error reading NDEF: $e');
              if (isEmptyNdefError(e)) {
                isEmpty = true;
              }
            }

            // Build result
            final result = {
              'tagId': tagId ?? 'unknown',
              'data': ndefData,
              'isEmpty': isEmpty || ndefData == null,
              'type': 'NFC Tag',
            };

            debugPrint('[NFC] Read complete - Data: ${ndefData ?? "empty"}, Tag ID: ${tagId ?? "unknown"}');

            // Stop session with success message
            await stopSession(
              alertMessage: ndefData != null ? 'Tag read successfully!' : 'Empty tag detected',
            );

            if (!completer.isCompleted) {
              completer.complete(result);
            }

          } catch (e, stackTrace) {
            debugPrint('[NFC] Error processing tag: $e');
            debugPrint('[NFC] Stack trace: $stackTrace');

            await stopSession(alertMessage: 'Failed to read tag');

            if (!completer.isCompleted) {
              completer.complete({'error': 'Error reading tag: $e'});
            }
          }
        },
      );

      debugPrint('[NFC] Session started, waiting for tag...');

      // Wait for result with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('[NFC] Session timeout');
          stopSession(alertMessage: 'Session timed out');
          return {'error': 'Session timed out'};
        },
      );

      debugPrint('[NFC] ========== Read Session Complete ==========');
      return result;

    } catch (e, stackTrace) {
      debugPrint('[NFC] Fatal error in read session: $e');
      debugPrint('[NFC] Stack trace: $stackTrace');
      await stopSession(alertMessage: 'Error occurred');
      return {'error': 'Failed to start NFC session: $e'};
    }
  }

  /// Write data to NFC tag
  static Future<Map<String, dynamic>> writeNFCTag({
    required String data,
    String? tagId,
  }) async {
    debugPrint('[NFC] ========== Starting NFC Write Session ==========');
    debugPrint('[NFC] Data to write: $data');

    try {
      // Stop any existing session
      await stopSession();
      await Future.delayed(const Duration(milliseconds: 500));

      // Check availability
      final isAvailable = await isNFCAvailable();
      if (!isAvailable) {
        return {'success': false, 'error': 'NFC not available'};
      }

      final status = await getNFCAvailabilityStatus();
      if (status != NfcAvailability.enabled) {
        return {'success': false, 'error': 'NFC is not enabled'};
      }

      final completer = Completer<Map<String, dynamic>>();

      _sessionActive = true;

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        alertMessageIos: 'Hold your iPhone near the NFC tag to write',
        invalidateAfterFirstReadIos: true,

        onSessionErrorIos: (error) {
          debugPrint('[NFC][iOS] Write session error: ${error.message}');
          if (!completer.isCompleted) {
            completer.complete({'success': false, 'error': error.message});
          }
          _sessionActive = false;
        },

        onDiscovered: (NfcTag tag) async {
          debugPrint('[NFC] Tag discovered for writing');

          try {
            final actualTagId = extractTagId(tag);
            debugPrint('[NFC] Writing to tag: ${actualTagId ?? "unknown"}');

            // Create NDEF message
            final payload = Uint8List.fromList([0x00, ...data.codeUnits]);
            final record = NdefRecord(
              typeNameFormat: TypeNameFormat.wellKnown,
              type: Uint8List.fromList([0x55]), // URI record
              identifier: Uint8List(0),
              payload: payload,
            );

            final message = NdefMessage(records: [record]);

            // Write based on platform
            bool writeSuccess = false;

            if (defaultTargetPlatform == TargetPlatform.iOS) {
              final ndef = NdefIos.from(tag);
              if (ndef != null) {
                await ndef.writeNdef(message);
                writeSuccess = true;
                debugPrint('[NFC][iOS] Write successful');
              } else {
                debugPrint('[NFC][iOS] Tag does not support NDEF writing');
              }
            } else if (defaultTargetPlatform == TargetPlatform.android) {
              final ndef = NdefAndroid.from(tag);
              if (ndef != null) {
                if (ndef.isWritable) {
                  await ndef.writeNdefMessage(message);
                  writeSuccess = true;
                  debugPrint('[NFC][Android] Write successful');
                } else {
                  debugPrint('[NFC][Android] Tag is not writable');
                }
              } else {
                debugPrint('[NFC][Android] Tag does not support NDEF');
              }
            }

            final result = {
              'success': writeSuccess,
              'tagId': actualTagId,
              'message': writeSuccess ? 'Write successful' : 'Write failed',
            };

            await stopSession(
              alertMessage: writeSuccess ? 'Tag written successfully!' : 'Write failed',
            );

            if (!completer.isCompleted) {
              completer.complete(result);
            }

          } catch (e, stackTrace) {
            debugPrint('[NFC] Error writing tag: $e');
            debugPrint('[NFC] Stack trace: $stackTrace');

            await stopSession(alertMessage: 'Write failed');

            if (!completer.isCompleted) {
              completer.complete({'success': false, 'error': 'Write error: $e'});
            }
          }
        },
      );

      // Wait for result with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('[NFC] Write timeout');
          stopSession(alertMessage: 'Write timeout');
          return {'success': false, 'error': 'Write timeout'};
        },
      );

      debugPrint('[NFC] ========== Write Session Complete ==========');
      return result;

    } catch (e, stackTrace) {
      debugPrint('[NFC] Fatal error in write session: $e');
      debugPrint('[NFC] Stack trace: $stackTrace');
      await stopSession();
      return {'success': false, 'error': 'Failed to write: $e'};
    }
  }

  // Registry methods
  static void registerNFCTagData(NFCTagData nfcData) {
    _nfcRegistry[nfcData.id] = nfcData;
    if (nfcData.tagId != null) {
      _tagIdToDataId[nfcData.tagId!] = nfcData.id;
    }
  }

  static NFCTagData? getNFCTagDataById(String id) {
    return _nfcRegistry[id];
  }

  static NFCTagData? getNFCTagDataByTagId(String tagId) {
    final dataId = _tagIdToDataId[tagId];
    if (dataId == null) return null;
    return _nfcRegistry[dataId];
  }

  static List<NFCTagData> getAllRegisteredTags() {
    return _nfcRegistry.values.toList();
  }

  static String generateDeepLink({
    required String data,
    String? tagId,
    String? customIdentifier,
    String? category,
  }) {
    final nfcData = NFCTagData.create(
      data: data,
      tagId: tagId,
      customIdentifier: customIdentifier,
      category: category,
    );
    registerNFCTagData(nfcData);
    return nfcData.buildDeepLink();
  }

  static bool verifySystemNFC(String scannedData) {
    if (NFCTagData.isSystemDeepLink(scannedData)) {
      return true;
    }
    return NFCTagData.verifySystemNFC(scannedData);
  }

  static NFCTagDetails extractTagDetails(NfcTag tag, {String? scannedData}) {
    try {
      // ignore: invalid_use_of_protected_member
      final tagData = tag.data;

      if (tagData is! Map) {
        return NFCTagDetails(scannedData: scannedData);
      }

      String? tagType;
      String? tagModel;
      String? serialNumber;
      String? sak;

      // Check NFC-A
      final nfca = tagData['nfca'];
      if (nfca is Map) {
        tagType = 'ISO 14443-3A';

        if (nfca['identifier'] != null) {
          serialNumber = (nfca['identifier'] as List)
              .map((e) => (e as int).toRadixString(16).padLeft(2, '0').toUpperCase())
              .join(':');
        }

        if (nfca['sak'] != null) {
          final sakValue = nfca['sak'] as int;
          sak = '0x${sakValue.toRadixString(16).padLeft(2, '0').toUpperCase()}';

          // Determine tag model from SAK
          if (sakValue == 0x00) {
            tagModel = 'NXP - NTAG213';
          } else if (sakValue == 0x08) {
            tagModel = 'NXP - NTAG215';
          } else if (sakValue == 0x10) {
            tagModel = 'NXP - NTAG216';
          } else {
            tagModel = 'ISO 14443 Type A';
          }
        }
      }

      return NFCTagDetails(
        tagType: tagType,
        tagModel: tagModel,
        serialNumber: serialNumber,
        sak: sak,
        scannedData: scannedData,
      );
    } catch (e) {
      debugPrint('[NFC] Error extracting tag details: $e');
      return NFCTagDetails(scannedData: scannedData);
    }
  }
}
