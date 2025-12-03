import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/src/nfc_manager_android/tags/ndef.dart' as android;
import 'package:nfc_manager/src/nfc_manager_ios/tags/ndef.dart' as ios;
import 'package:ndef_record/ndef_record.dart';
import '../models/nfc_tag_data.dart';

/// NFC Service for reading, writing, and managing NFC tags.
class NFCService {
  /// In-memory registry of NFCTagData by id for this POC.
  ///
  /// In a production system this would be backed by a database or API.
  static final Map<String, NFCTagData> _nfcRegistry = <String, NFCTagData>{};

  /// Registry by tag ID (physical NFC tag identifier)
  static final Map<String, String> _tagIdToDataId = <String, String>{};

  /// Register an NFC entry in the in-memory registry.
  static void registerNFCTagData(NFCTagData nfcData) {
    _nfcRegistry[nfcData.id] = nfcData;
    if (nfcData.tagId != null) {
      _tagIdToDataId[nfcData.tagId!] = nfcData.id;
    }
  }

  /// Look up NFC data by id from the registry.
  static NFCTagData? getNFCTagDataById(String id) {
    return _nfcRegistry[id];
  }

  /// Look up NFC data by tag ID (physical tag identifier).
  static NFCTagData? getNFCTagDataByTagId(String tagId) {
    final dataId = _tagIdToDataId[tagId];
    if (dataId == null) return null;
    return _nfcRegistry[dataId];
  }

  /// Get all registered NFC tags.
  static List<NFCTagData> getAllRegisteredTags() {
    return _nfcRegistry.values.toList();
  }

  /// Check if NFC is available on the device.
  static Future<bool> isNFCAvailable() async {
    try {
      final result = await NfcManager.instance.checkAvailability();
      return result == NfcAvailability.enabled;
    } catch (e) {
      debugPrint('Error checking NFC availability: $e');
      return false;
    }
  }

  /// Generate a deep link for a new NFC entry and register it.
  ///
  /// The deep link has the format: `sss://qr/<id>` (same as QR codes).
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

  /// Read NFC tag and extract data.
  ///
  /// Returns the scanned data as a string, or null if reading failed.
  static Future<Map<String, dynamic>?> readNFCTag() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      final isAvailable = availability == NfcAvailability.enabled;
      if (!isAvailable) {
        debugPrint('NFC is not available on this device');
        return null;
      }

      String? scannedData;
      String? tagId;
      Map<String, dynamic>? tagInfo;

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            // Extract tag ID - use tag identifier if available
            try {
              // Try to get identifier from tag data
              // ignore: invalid_use_of_protected_member
              final tagData = tag.data;
              if (tagData is Map) {
                // Try different tag types
                final nfca = tagData['nfca'];
                final nfcb = tagData['nfcb'];
                final nfcf = tagData['nfcf'];
                final nfcv = tagData['nfcv'];
                
                if (nfca is Map && nfca['identifier'] != null) {
                  tagId = (nfca['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                } else if (nfcb is Map && nfcb['identifier'] != null) {
                  tagId = (nfcb['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                } else if (nfcf is Map && nfcf['identifier'] != null) {
                  tagId = (nfcf['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                } else if (nfcv is Map && nfcv['identifier'] != null) {
                  tagId = (nfcv['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                } else {
                  tagId = 'unknown';
                }
              } else {
                tagId = 'unknown';
              }
            } catch (e) {
              tagId = 'unknown';
            }

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
                      scannedData = uriString;
                    }
                  } else {
                    // Text record or other well-known type
                    scannedData = String.fromCharCodes(record.payload);
                  }
                } else if (record.typeNameFormat == TypeNameFormat.absoluteUri) {
                  // Absolute URI
                  scannedData = String.fromCharCodes(record.payload);
                } else {
                  // Other types - try to decode as string
                  scannedData = String.fromCharCodes(record.payload);
                }
              }
            }

            // Store tag information
            tagInfo = {
              'tagId': tagId,
              'data': scannedData,
              'type': 'NFC Tag',
            };

            await NfcManager.instance.stopSession();
          } catch (e) {
            debugPrint('Error reading NFC tag: $e');
            await NfcManager.instance.stopSession();
          }
        },
      );

      return tagInfo;
    } catch (e) {
      debugPrint('Error starting NFC session: $e');
      return null;
    }
  }

  /// Write data to NFC tag.
  ///
  /// Returns true if write was successful, false otherwise.
  static Future<bool> writeNFCTag({
    required String data,
    String? tagId,
    String? customIdentifier,
    String? category,
  }) async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      final isAvailable = availability == NfcAvailability.enabled;
      if (!isAvailable) {
        debugPrint('NFC is not available on this device');
        return false;
      }

      bool writeSuccess = false;
      String? actualTagId;

      // Generate deep link for the data
      final deepLink = generateDeepLink(
        data: data,
        tagId: tagId,
        customIdentifier: customIdentifier,
        category: category,
      );

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            // Extract tag ID - use tag identifier if available
            try {
              // ignore: invalid_use_of_protected_member
              final tagData = tag.data;
              if (tagData is Map) {
                final nfca = tagData['nfca'];
                final nfcb = tagData['nfcb'];
                final nfcf = tagData['nfcf'];
                final nfcv = tagData['nfcv'];
                
                if (nfca is Map && nfca['identifier'] != null) {
                  actualTagId = (nfca['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                } else if (nfcb is Map && nfcb['identifier'] != null) {
                  actualTagId = (nfcb['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                } else if (nfcf is Map && nfcf['identifier'] != null) {
                  actualTagId = (nfcf['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                } else if (nfcv is Map && nfcv['identifier'] != null) {
                  actualTagId = (nfcv['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                } else {
                  actualTagId = 'unknown';
                }
              } else {
                actualTagId = 'unknown';
              }
            } catch (e) {
              actualTagId = 'unknown';
            }

            // Check if tag supports NDEF
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
            
            if (ndefAndroid == null && ndefIos == null) {
              await NfcManager.instance.stopSession();
              return;
            }

            // Check if tag is writable (Android only)
            if (ndefAndroid != null && !ndefAndroid.isWritable) {
              await NfcManager.instance.stopSession();
              return;
            }

            // Create NDEF message with deep link
            // For URI records, type is [0x55] and payload is the URI string
            final uriBytes = deepLink.codeUnits;
            final ndefRecord = NdefRecord(
              typeNameFormat: TypeNameFormat.wellKnown,
              type: Uint8List.fromList([0x55]), // URI record type
              identifier: Uint8List(0),
              payload: Uint8List.fromList(uriBytes),
            );

            final ndefMessage = NdefMessage(records: [ndefRecord]);

            // Write to tag
            if (ndefAndroid != null) {
              await ndefAndroid.writeNdefMessage(ndefMessage);
            } else if (ndefIos != null) {
              await ndefIos.writeNdef(ndefMessage);
            }

            // Update registry with actual tag ID
            final nfcData = NFCTagData.create(
              data: data,
              tagId: actualTagId,
              customIdentifier: customIdentifier,
              category: category,
            );
            registerNFCTagData(nfcData);

            writeSuccess = true;
            await NfcManager.instance.stopSession();
          } catch (e) {
            debugPrint('Error writing NFC tag: $e');
            await NfcManager.instance.stopSession();
            writeSuccess = false;
          }
        },
      );

      return writeSuccess;
    } catch (e) {
      debugPrint('Error starting NFC write session: $e');
      return false;
    }
  }

  /// Verify if a scanned NFC tag was created by this system.
  static bool verifySystemNFC(String scannedData) {
    // First, check if it is one of our deep links.
    if (NFCTagData.isSystemDeepLink(scannedData)) {
      return true;
    }

    // Fallback: support legacy JSON-based payloads.
    return NFCTagData.verifySystemNFC(scannedData);
  }

  /// Extract tag ID from NFC tag.
  static String? extractTagId(NfcTag tag) {
    try {
      // ignore: invalid_use_of_protected_member
      final tagData = tag.data;
      if (tagData is Map) {
        final nfca = tagData['nfca'];
        final nfcb = tagData['nfcb'];
        final nfcf = tagData['nfcf'];
        final nfcv = tagData['nfcv'];
        
        if (nfca is Map && nfca['identifier'] != null) {
          return (nfca['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
        } else if (nfcb is Map && nfcb['identifier'] != null) {
          return (nfcb['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
        } else if (nfcf is Map && nfcf['identifier'] != null) {
          return (nfcf['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
        } else if (nfcv is Map && nfcv['identifier'] != null) {
          return (nfcv['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting tag ID: $e');
      return null;
    }
  }
}

