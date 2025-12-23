import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Branded QR Card widget with title, icon, border, and customizable colors
class BrandedQRCard extends StatelessWidget {
  /// The data to encode in the QR code
  final String data;

  /// Title/category text displayed above the QR code
  final String? title;

  /// Optional embedded identifier (letter or emoji) in the center
  final String? embeddedIdentifier;

  /// Size of the QR code itself (not including padding/border)
  final double qrSize;

  /// Foreground color of the QR code
  final Color foregroundColor;

  /// Background color of the QR code
  final Color backgroundColor;

  /// Color for the embedded identifier text
  final Color? embeddedIdentifierColor;

  /// Border style: true for rounded, false for square
  final bool roundedBorder;

  /// Border width
  final double borderWidth;

  /// Border color
  final Color borderColor;

  /// Padding around the QR code
  final double padding;

  /// Show magnifying glass icon in corner
  final bool showIcon;

  /// Icon color
  final Color iconColor;

  const BrandedQRCard({
    super.key,
    required this.data,
    this.title,
    this.embeddedIdentifier,
    this.qrSize = 200,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.embeddedIdentifierColor,
    this.roundedBorder = true,
    this.borderWidth = 2.0,
    this.borderColor = Colors.grey,
    this.padding = 16.0,
    this.showIcon = true,
    this.iconColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    // Build the base QR widget directly using QrImageView
    // The data parameter should already be a deep link URL
    Widget baseQR = QrImageView(
      data: data,
      size: qrSize,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    // Add embedded identifier overlay if provided
    Widget qrWidget;
    if (embeddedIdentifier != null && embeddedIdentifier!.isNotEmpty) {
      // Check if identifier is an emoji
      final isEmoji = embeddedIdentifier!.length > 1 || 
                      embeddedIdentifier!.runes.length > 1 ||
                      RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(embeddedIdentifier!);
      
      final fontSize = isEmoji ? qrSize * 0.15 : qrSize * 0.12;
      
      qrWidget = Stack(
        alignment: Alignment.center,
        children: [
          baseQR,
          Container(
            width: qrSize * 0.2,
            height: qrSize * 0.2,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                embeddedIdentifier!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: embeddedIdentifierColor ?? foregroundColor,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      qrWidget = baseQR;
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        borderRadius: roundedBorder
            ? BorderRadius.circular(12)
            : BorderRadius.circular(0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title above QR code
          if (title != null && title!.isNotEmpty) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: padding),
          ],

          // QR code with icon overlay
          Stack(
            children: [
              qrWidget,
              // Magnifying glass icon in top-right corner
              if (showIcon)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

