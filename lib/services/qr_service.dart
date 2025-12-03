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

/// QR Service for generating, exporting, and sharing QR codes
class QRService {
  /// Generate QR data JSON string with system identifier
  static String generateQRData({
    required String data,
    String? customIdentifier,
  }) {
    final qrData = QRData.create(
      data: data,
      customIdentifier: customIdentifier,
    );
    return qrData.toJsonString();
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
    final qrData = generateQRData(data: data);
    
    return QrImageView(
      data: qrData,
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

  /// Create QR widget with embedded letter overlay
  static Widget createQRWidgetWithLetter({
    required String data,
    required String embeddedLetter,
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
    Color? embeddedLetterColor,
  }) {
    final qrData = generateQRData(data: data);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        QrImageView(
          data: qrData,
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
              embeddedLetter.toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.12,
                fontWeight: FontWeight.bold,
                color: embeddedLetterColor ?? foregroundColor ?? Colors.black,
              ),
            ),
          ),
        ),
      ],
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

      final filePath = await FileUtils.getFilePath(fileName);
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

      final filePath = await FileUtils.getFilePath(fileName);
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
    return QRData.verifySystemQR(scannedData);
  }
}

