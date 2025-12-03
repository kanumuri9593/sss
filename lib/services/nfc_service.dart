import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/src/nfc_manager_android/tags/ndef.dart' as android;
import 'package:nfc_manager/src/nfc_manager_ios/tags/ndef.dart' as ios;
import 'package:ndef_record/ndef_record.dart';
import '../models/nfc_tag_data.dart';
import '../models/nfc_tag_details.dart';

/// NFC Service for reading, writing, and managing NFC tags.
class NFCService {
  /// In-memory registry of NFCTagData by id for this POC.
  ///
  /// In a production system this would be backed by a database or API.
  static final Map<String, NFCTagData> _nfcRegistry = <String, NFCTagData>{};

  /// Registry by tag ID (physical NFC tag identifier)
  static final Map<String, String> _tagIdToDataId = <String, String>{};

  /// Check if an error indicates an empty/unformatted NDEF tag.
  /// 
  /// This is a normal case and should be handled gracefully.
  static bool _isEmptyNdefError(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('NDEF') && 
           (errorString.contains('does not contain') || 
            errorString.contains('403') ||
            errorString.contains('message') ||
            errorString.contains('no NDEF'));
  }

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
      debugPrint('NFC Availability Status: $result');
      // On iOS, NFC can be enabled, disabled, or unsupported
      // We return true only if it's enabled
      final isAvailable = result == NfcAvailability.enabled;
      if (!isAvailable) {
        debugPrint('NFC Status: $result (enabled=${NfcAvailability.enabled})');
        if (result == NfcAvailability.disabled) {
          debugPrint('NFC is disabled. Please enable NFC in Settings > General > NFC.');
        } else if (result == NfcAvailability.unsupported) {
          debugPrint('NFC is not supported on this device.');
        }
      }
      return isAvailable;
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
      bool sessionStopped = false;

      debugPrint('Starting NFC read session...');

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,  // NTAG 213 uses ISO14443 Type A
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          debugPrint('NFC tag discovered!');
          
          try {
            // Extract tag ID - use tag identifier if available
            try {
              // Try to get identifier from tag data
              // ignore: invalid_use_of_protected_member
              final tagData = tag.data;
              debugPrint('Tag data type: ${tagData.runtimeType}');
              
              if (tagData is Map) {
                // Try different tag types
                final nfca = tagData['nfca'];
                final nfcb = tagData['nfcb'];
                final nfcf = tagData['nfcf'];
                final nfcv = tagData['nfcv'];
                
                debugPrint('Tag types found - nfca: ${nfca != null}, nfcb: ${nfcb != null}, nfcf: ${nfcf != null}, nfcv: ${nfcv != null}');
                
                if (nfca is Map && nfca['identifier'] != null) {
                  tagId = (nfca['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                  debugPrint('Tag ID extracted (NFCA): $tagId');
                } else if (nfcb is Map && nfcb['identifier'] != null) {
                  tagId = (nfcb['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                  debugPrint('Tag ID extracted (NFCB): $tagId');
                } else if (nfcf is Map && nfcf['identifier'] != null) {
                  tagId = (nfcf['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                  debugPrint('Tag ID extracted (NFCF): $tagId');
                } else if (nfcv is Map && nfcv['identifier'] != null) {
                  tagId = (nfcv['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
                  debugPrint('Tag ID extracted (NFCV): $tagId');
                } else {
                  tagId = 'unknown';
                  debugPrint('Could not extract tag ID from known types');
                }
              } else {
                tagId = 'unknown';
                debugPrint('Tag data is not a Map, cannot extract ID');
              }
            } catch (e, stackTrace) {
              debugPrint('Error extracting tag ID: $e');
              debugPrint('Stack trace: $stackTrace');
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
              debugPrint('NDEF handler - Android: ${ndefAndroid != null}, iOS: ${ndefIos != null}');
            } catch (e) {
              debugPrint('Error getting Ndef handler: $e');
            }
            
            if (ndefAndroid != null || ndefIos != null) {
              NdefMessage? ndefMessage;
              try {
                if (ndefAndroid != null) {
                  ndefMessage = await ndefAndroid.getNdefMessage();
                  debugPrint('NDEF message from Android: ${ndefMessage != null ? "found" : "null"}');
                } else if (ndefIos != null) {
                  ndefMessage = ndefIos.cachedNdefMessage ?? await ndefIos.readNdef();
                  debugPrint('NDEF message from iOS: ${ndefMessage != null ? "found" : "null"}');
                }
              } catch (e) {
                debugPrint('Error reading NDEF message: $e');
                
                // Check if this is the "empty NDEF" error (iOS error 403)
                // This is a normal case for empty/unformatted tags
                if (_isEmptyNdefError(e)) {
                  debugPrint('Tag is empty/unformatted (no NDEF data) - this is normal');
                  // This is OK - tag is detected but empty
                  ndefMessage = null;
                } else {
                  debugPrint('Unexpected error reading NDEF: $e');
                  // Continue anyway - we still have the tag ID
                  ndefMessage = null;
                }
              }
              
              if (ndefMessage != null && ndefMessage.records.isNotEmpty) {
                debugPrint('Found ${ndefMessage.records.length} NDEF record(s)');
                final record = ndefMessage.records.first;
                debugPrint('Record type: ${record.typeNameFormat}, type bytes: ${record.type}');
                
                if (record.typeNameFormat == TypeNameFormat.wellKnown) {
                  if (record.type.length >= 1 && record.type[0] == 0x55) {
                    // URI record (0x55 is the prefix code for URI)
                    final uriBytes = record.payload;
                    if (uriBytes.isNotEmpty) {
                      final uriString = String.fromCharCodes(uriBytes.skip(1));
                      scannedData = uriString;
                      debugPrint('Extracted URI: $scannedData');
                    }
                  } else {
                    // Text record or other well-known type
                    scannedData = String.fromCharCodes(record.payload);
                    debugPrint('Extracted text: $scannedData');
                  }
                } else if (record.typeNameFormat == TypeNameFormat.absoluteUri) {
                  // Absolute URI
                  scannedData = String.fromCharCodes(record.payload);
                  debugPrint('Extracted absolute URI: $scannedData');
                } else {
                  // Other types - try to decode as string
                  scannedData = String.fromCharCodes(record.payload);
                  debugPrint('Extracted other type: $scannedData');
                }
              } else {
                debugPrint('Tag detected but has no NDEF data (empty/unformatted tag)');
                // This is OK - tag is detected but empty
              }
            } else {
              debugPrint('Tag does not support NDEF format');
            }

            // Store tag information - include tag even if empty
            tagInfo = {
              'tagId': tagId,
              'data': scannedData,  // Can be null if tag is empty
              'type': 'NFC Tag',
              'isEmpty': scannedData == null,
            };

            debugPrint('Tag read complete - ID: $tagId, Data: ${scannedData ?? "empty"}');

            await NfcManager.instance.stopSession();
            sessionStopped = true;
          } catch (e, stackTrace) {
            debugPrint('Error reading NFC tag: $e');
            debugPrint('Stack trace: $stackTrace');
            
            if (!sessionStopped) {
              try {
                await NfcManager.instance.stopSession();
                sessionStopped = true;
              } catch (stopError) {
                debugPrint('Error stopping session: $stopError');
              }
            }
            
            // Still return tag info if we got the tag ID
            if (tagId != null && tagId != 'unknown') {
              tagInfo = {
                'tagId': tagId,
                'data': null,
                'type': 'NFC Tag',
                'isEmpty': true,
                'error': e.toString(),
              };
            }
          }
        },
      );

      return tagInfo;
    } catch (e, stackTrace) {
      debugPrint('Error starting NFC session: $e');
      debugPrint('Stack trace: $stackTrace');
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
            // For URI records, payload must start with URI prefix byte
            // 0x00 = no prefix (absolute URI), since we're writing a full URI (sss://...)
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

  /// Extract detailed technical information from an NFC tag.
  static NFCTagDetails extractTagDetails(NfcTag tag, {String? scannedData}) {
    try {
      // ignore: invalid_use_of_protected_member
      final tagData = tag.data;
      
      String? tagType;
      String? tagModel;
      String? technologiesAvailable;
      String? serialNumber;
      String? atqa;
      String? sak;
      bool? protectedByPassword;
      String? memoryInformation;
      String? dataFormat;
      bool? writable;

      if (tagData is Map) {
        final nfca = tagData['nfca'];
        final nfcb = tagData['nfcb'];
        final nfcf = tagData['nfcf'];
        final nfcv = tagData['nfcv'];

        // Process NFCA (ISO 14443 Type A)
        if (nfca is Map) {
          tagType = 'ISO 14443-3A';
          technologiesAvailable = 'Type A';
          
          if (nfca['identifier'] != null) {
            serialNumber = (nfca['identifier'] as List)
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':');
          }
          
          if (nfca['atqa'] != null) {
            final atqaValue = nfca['atqa'];
            if (atqaValue is List && atqaValue.isNotEmpty) {
              // ATQA is typically 2 bytes
              final atqaBytes = atqaValue.map((e) => (e as int).toRadixString(16).padLeft(2, '0')).join('');
              atqa = '0x${atqaBytes.toUpperCase()}';
            } else if (atqaValue is int) {
              atqa = '0x${atqaValue.toRadixString(16).padLeft(4, '0').toUpperCase()}';
            }
          }
          
          if (nfca['sak'] != null) {
            final sakValue = nfca['sak'];
            if (sakValue is int) {
              sak = '0x${sakValue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
            }
          }

          // Try to determine tag model from SAK and other characteristics
          if (sak != null) {
            final sakInt = int.tryParse(sak.replaceFirst('0x', ''), radix: 16);
            if (sakInt != null) {
              // Common SAK values for NTAG tags
              if (sakInt == 0x00) {
                tagModel = 'NXP - NTAG213';
                memoryInformation = '180 bytes : 45 pages (4 bytes each)';
                dataFormat = 'NFC Forum Type 2';
              } else if (sakInt == 0x08) {
                tagModel = 'NXP - NTAG215';
                memoryInformation = '504 bytes : 126 pages (4 bytes each)';
                dataFormat = 'NFC Forum Type 2';
              } else if (sakInt == 0x10) {
                tagModel = 'NXP - NTAG216';
                memoryInformation = '888 bytes : 222 pages (4 bytes each)';
                dataFormat = 'NFC Forum Type 2';
              } else {
                tagModel = 'ISO 14443 Type A';
              }
            }
          }

          // Check if tag is protected by password (NTAG tags)
          // This is typically indicated by specific memory configurations
          protectedByPassword = false; // Default, would need additional checks
        }
        // Process NFCB (ISO 14443 Type B)
        else if (nfcb is Map) {
          tagType = 'ISO 14443-3B';
          technologiesAvailable = 'Type B';
          
          if (nfcb['identifier'] != null) {
            serialNumber = (nfcb['identifier'] as List)
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':');
          }
          
          if (nfcb['atqb'] != null) {
            final atqb = nfcb['atqb'];
            if (atqb is Map && atqb['applicationData'] != null) {
              // ATQB contains application data
              final appData = atqb['applicationData'];
              if (appData is List) {
                final atqbBytes = appData.map((e) => (e as int).toRadixString(16).padLeft(2, '0')).join('');
                atqa = '0x${atqbBytes.toUpperCase()}';
              }
            }
          }
        }
        // Process NFCF (FeliCa)
        else if (nfcf is Map) {
          tagType = 'FeliCa';
          technologiesAvailable = 'Type F';
          
          if (nfcf['id'] != null) {
            final id = nfcf['id'];
            if (id is List) {
              serialNumber = id.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
            }
          }
        }
        // Process NFCV (ISO 15693)
        else if (nfcv is Map) {
          tagType = 'ISO 15693';
          technologiesAvailable = 'Type V';
          
          if (nfcv['identifier'] != null) {
            serialNumber = (nfcv['identifier'] as List)
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':');
          }
        }

        // Check if tag supports NDEF and is writable
        android.NdefAndroid? ndefAndroid;
        ios.NdefIos? ndefIos;
        try {
          ndefAndroid = android.NdefAndroid.from(tag);
          if (ndefAndroid == null) {
            ndefIos = ios.NdefIos.from(tag);
          }
        } catch (e) {
          debugPrint('Error getting Ndef for details: $e');
        }

        if (ndefAndroid != null) {
          writable = ndefAndroid.isWritable;
          if (dataFormat == null) {
            dataFormat = 'NFC Forum Type 2'; // Most common for Android
          }
        } else if (ndefIos != null) {
          // iOS doesn't expose writable status directly
          writable = null;
          if (dataFormat == null) {
            dataFormat = 'NFC Forum Type 2'; // Most common for iOS
          }
        } else {
          writable = false;
        }
      }

      return NFCTagDetails(
        tagType: tagType,
        tagModel: tagModel,
        technologiesAvailable: technologiesAvailable,
        serialNumber: serialNumber,
        atqa: atqa,
        sak: sak,
        protectedByPassword: protectedByPassword,
        memoryInformation: memoryInformation,
        dataFormat: dataFormat,
        writable: writable,
        scannedData: scannedData,
      );
    } catch (e, stackTrace) {
      debugPrint('Error extracting tag details: $e');
      debugPrint('Stack trace: $stackTrace');
      return NFCTagDetails(scannedData: scannedData);
    }
  }
}

