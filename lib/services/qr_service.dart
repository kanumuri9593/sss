import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import '../models/qr_data.dart';
import '../utils/file_utils.dart';

/// QR Service for generating, exporting, sharing, and resolving QR codes.
class QRService {
  /// In-memory registry of QRData by id for this POC.
  ///
  /// In a production system this would be backed by a database or API.
  static final Map<String, QRData> _qrRegistry = <String, QRData>{};

  /// Register a QR entry in the in-memory registry.
  static void registerQRData(QRData qrData) {
    _qrRegistry[qrData.id] = qrData;
  }

  /// Look up QR data by id from the registry.
  static QRData? getQRDataById(String id) {
    return _qrRegistry[id];
  }

  /// Generate QR data JSON string with system identifier.
  ///
  /// This is kept for backwards compatibility and internal checks.
  static String generateQRData({
    required String data,
    String? customIdentifier,
  }) {
    final qrData = QRData.create(
      data: data,
      customIdentifier: customIdentifier,
    );
    registerQRData(qrData);
    return qrData.toJsonString();
  }

  /// Generate a deep link for a new QR entry and register it.
  ///
  /// The deep link has the format: `sss://qr/<id>`.
  static String generateDeepLink({
    required String data,
    String? customIdentifier,
    String? category,
  }) {
    final qrData = QRData.create(
      data: data,
      customIdentifier: customIdentifier,
      category: category,
    );
    registerQRData(qrData);
    return qrData.buildDeepLink();
  }

  /// Create QR widget with optional embedded image or letter
  static Widget createQRWidget({
    required String data,
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
    String? embeddedImagePath,
    String? embeddedLetter,
    Color? embeddedLetterColor,
  }) {
    // For visual QR code generation we now encode the deep link so
    // that native camera apps can deep link directly into this app.
    final deepLink = generateDeepLink(data: data, customIdentifier: embeddedLetter);

    return QrImageView(
      data: deepLink,
      size: size,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      embeddedImage: embeddedImagePath != null
          ? AssetImage(embeddedImagePath) as ImageProvider?
          : null,
      embeddedImageStyle: embeddedImagePath != null
          ? const QrEmbeddedImageStyle(
              size: Size(40, 40),
            )
          : null,
      // For embedded letter, we'll use a custom painter approach
      // qr_flutter doesn't directly support text, so we'll overlay it
    );
  }

  /// Convert RepaintBoundary to image bytes using GlobalKey
  static Future<Uint8List?> captureWidgetToImage({
    required GlobalKey repaintBoundaryKey,
    double pixelRatio = 3.0,
  }) async {
    try {
      final RenderRepaintBoundary? boundary =
          repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('RepaintBoundary not found');
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget to image: $e');
      return null;
    }
  }

  /// Create QR widget with embedded identifier (letter or emoji) overlay
  static Widget createQRWidgetWithIdentifier({
    required String data,
    required String embeddedIdentifier,
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
    Color? embeddedIdentifierColor,
  }) {
    // Encode deep link as QR payload.
    final deepLink = generateDeepLink(
      data: data,
      customIdentifier: embeddedIdentifier,
    );

    // Check if identifier is an emoji (emojis are typically longer in character count)
    final isEmoji = embeddedIdentifier.length > 1 || 
                    embeddedIdentifier.runes.length > 1 ||
                    RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(embeddedIdentifier);
    
    // Use larger font size for emojis, smaller for letters
    final fontSize = isEmoji ? size * 0.15 : size * 0.12;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        QrImageView(
          data: deepLink,
          size: size,
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: foregroundColor ?? Colors.black,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ),
        Container(
          width: size * 0.2,
          height: size * 0.2,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              embeddedIdentifier, // Don't uppercase - preserves emojis and case
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: embeddedIdentifierColor ?? foregroundColor ?? Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Deprecated: Use createQRWidgetWithIdentifier instead
  @Deprecated('Use createQRWidgetWithIdentifier instead')
  static Widget createQRWidgetWithLetter({
    required String data,
    required String embeddedLetter,
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
    Color? embeddedLetterColor,
  }) {
    return createQRWidgetWithIdentifier(
      data: data,
      embeddedIdentifier: embeddedLetter,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      embeddedIdentifierColor: embeddedLetterColor,
    );
  }

  /// Export QR code as PNG file from captured image bytes
  static Future<String?> exportAsPNG({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          debugPrint('Storage permission not granted');
          return null;
        }
      }

      final filePath = await FileUtils.getDownloadFilePath(fileName);
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      debugPrint('Error exporting PNG: $e');
      return null;
    }
  }

  /// Export QR code as PDF file from captured image bytes
  static Future<String?> exportAsPDF({
    required Uint8List imageBytes,
    required String fileName,
    required String data,
    double size = 200,
    String? title,
    String? description,
  }) async {
    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          debugPrint('Storage permission not granted');
          return null;
        }
      }

      final pdf = pw.Document();
      final qrData = QRData.create(data: data);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (title != null)
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                if (title != null) pw.SizedBox(height: 20),
                pw.Image(
                  pw.MemoryImage(imageBytes),
                  width: size,
                  height: size,
                ),
                if (description != null) pw.SizedBox(height: 20),
                if (description != null)
                  pw.Text(
                    description,
                    style: const pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Generated: ${qrData.timestamp}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'System: ${QRData.systemId}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      final filePath = await FileUtils.getDownloadFilePath(fileName);
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      return null;
    }
  }

  /// Share file via system share sheet (email, etc.)
  static Future<bool> shareFile({
    required String filePath,
    String? subject,
    String? text,
  }) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        subject: subject,
        text: text,
      );
      return true;
    } catch (e) {
      debugPrint('Error sharing file: $e');
      return false;
    }
  }

  /// Verify if a scanned QR code was created by this system
  static bool verifySystemQR(String scannedData) {
    // First, check if it is one of our deep links.
    if (QRData.isSystemDeepLink(scannedData)) {
      return true;
    }

    // Fallback: support legacy JSON-based payloads.
    return QRData.verifySystemQR(scannedData);
  }
}

