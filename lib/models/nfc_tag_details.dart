/// Model for storing detailed technical information about an NFC tag
class NFCTagDetails {
  /// Tag type (e.g., "ISO 14443-3A")
  final String? tagType;
  
  /// Tag manufacturer/model (e.g., "NXP - NTAG213")
  final String? tagModel;
  
  /// Technologies available (e.g., "Type A")
  final String? technologiesAvailable;
  
  /// Serial number (tag identifier)
  final String? serialNumber;
  
  /// ATQA (Answer To Request Type A) value
  final String? atqa;
  
  /// SAK (Select Acknowledge) value
  final String? sak;
  
  /// Whether the tag is protected by password
  final bool? protectedByPassword;
  
  /// Memory information (e.g., "180 bytes : 45 pages (4 bytes each)")
  final String? memoryInformation;
  
  /// Data format (e.g., "NFC Forum Type 2")
  final String? dataFormat;
  
  /// Whether the tag is writable
  final bool? writable;
  
  /// Scanned data from the tag (if any)
  final String? scannedData;

  NFCTagDetails({
    this.tagType,
    this.tagModel,
    this.technologiesAvailable,
    this.serialNumber,
    this.atqa,
    this.sak,
    this.protectedByPassword,
    this.memoryInformation,
    this.dataFormat,
    this.writable,
    this.scannedData,
  });

  /// Create NFCTagDetails from a Map
  factory NFCTagDetails.fromMap(Map<String, dynamic> map) {
    return NFCTagDetails(
      tagType: map['tagType'] as String?,
      tagModel: map['tagModel'] as String?,
      technologiesAvailable: map['technologiesAvailable'] as String?,
      serialNumber: map['serialNumber'] as String?,
      atqa: map['atqa'] as String?,
      sak: map['sak'] as String?,
      protectedByPassword: map['protectedByPassword'] as bool?,
      memoryInformation: map['memoryInformation'] as String?,
      dataFormat: map['dataFormat'] as String?,
      writable: map['writable'] as bool?,
      scannedData: map['scannedData'] as String?,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'tagType': tagType,
      'tagModel': tagModel,
      'technologiesAvailable': technologiesAvailable,
      'serialNumber': serialNumber,
      'atqa': atqa,
      'sak': sak,
      'protectedByPassword': protectedByPassword,
      'memoryInformation': memoryInformation,
      'dataFormat': dataFormat,
      'writable': writable,
      'scannedData': scannedData,
    };
  }
}

