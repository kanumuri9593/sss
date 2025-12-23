import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_service.dart';

/// QR Scanner Screen for scanning QR codes
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  String? _scannedData;
  bool _isVerified = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final Barcode barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _isProcessing = true;
      _scannedData = barcode.rawValue;
    });

    // Stop scanning after successful scan
    _controller.stop();

    // Verify if QR code was created by this system
    final isVerified = QRService.verifySystemQR(_scannedData!);
    setState(() {
      _isVerified = isVerified;
      _isProcessing = false;
    });
  }

  void _resumeScanning() {
    setState(() {
      _scannedData = null;
      _isVerified = false;
      _isProcessing = false;
    });
    _controller.start();
  }

  void _useScannedData() {
    if (_scannedData != null) {
      Navigator.pop(context, _scannedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Scanner view
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleScan,
                ),
                // Overlay with scanning area indicator
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.all(40),
                ),
              ],
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
                          color: _isVerified ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isVerified ? Icons.verified : Icons.info_outline,
                              color: _isVerified ? Colors.green[900] : Colors.orange[900],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isVerified
                                    ? '✓ Verified - Created by SSS System'
                                    : '⚠ Not created by this system',
                                style: TextStyle(
                                  color: _isVerified ? Colors.green[900] : Colors.orange[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
                              onPressed: _resumeScanning,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Scan Again'),
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
                                backgroundColor: Theme.of(context).primaryColor,
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
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Point camera at QR code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Position the QR code within the frame',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
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

