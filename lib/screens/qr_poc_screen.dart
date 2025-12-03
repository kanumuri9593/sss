import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/qr_data.dart';
import '../services/qr_service.dart';
import '../widgets/branded_qr_card.dart';
import 'qr_scanner_screen.dart';

/// Color theme presets for QR codes
class QRColorTheme {
  final String name;
  final Color foreground;
  final Color background;

  const QRColorTheme({
    required this.name,
    required this.foreground,
    required this.background,
  });

  static const List<QRColorTheme> presets = [
    QRColorTheme(name: 'Black/White', foreground: Colors.black, background: Colors.white),
    QRColorTheme(name: 'Blue/Light', foreground: Color(0xFF1976D2), background: Color(0xFFE3F2FD)),
    QRColorTheme(name: 'Green/Light', foreground: Color(0xFF388E3C), background: Color(0xFFE8F5E9)),
    QRColorTheme(name: 'Purple/Light', foreground: Color(0xFF7B1FA2), background: Color(0xFFF3E5F5)),
    QRColorTheme(name: 'Red/Light', foreground: Color(0xFFD32F2F), background: Color(0xFFFFEBEE)),
  ];
}

/// POC Screen for testing QR code generation and export features
class QRPOCScreen extends StatefulWidget {
  const QRPOCScreen({super.key});

  @override
  State<QRPOCScreen> createState() => _QRPOCScreenState();
}

class _QRPOCScreenState extends State<QRPOCScreen> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  final FocusNode _dataFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _identifierFocusNode = FocusNode();
  
  String _currentData = '';
  String? _title;
  String? _embeddedIdentifier;
  QRColorTheme _selectedTheme = QRColorTheme.presets[0];
  bool _roundedBorder = true;
  bool _isGenerating = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _dataController.text = 'Sample QR Code Data';
    _currentData = _dataController.text;
  }

  @override
  void dispose() {
    _dataController.dispose();
    _titleController.dispose();
    _identifierController.dispose();
    _dataFocusNode.dispose();
    _titleFocusNode.dispose();
    _identifierFocusNode.dispose();
    super.dispose();
  }

  void _generateQR() {
    setState(() {
      _currentData = _dataController.text.trim();
      _title = _titleController.text.trim().isEmpty 
          ? null 
          : _titleController.text.trim();
      _embeddedIdentifier = _identifierController.text.trim().isEmpty 
          ? null 
          : _identifierController.text.trim();
      _statusMessage = null;
    });
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
  }

  void _navigateToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    ).then((scannedData) {
      if (scannedData != null && scannedData is String) {
        setState(() {
          _dataController.text = scannedData;
          _currentData = scannedData;
        });
        _showMessage('Scanned data loaded', true);
      }
    });
  }

  String _generateFileName(String extension) {
    final sanitizedTitle = _title?.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_') ?? 'qr_code';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${sanitizedTitle}_$timestamp.$extension';
  }

  Future<void> _exportAsPNG() async {
    if (_currentData.isEmpty) {
      _showMessage('Please enter data first', false);
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = null;
    });

    try {
      // Capture the QR widget as image
      final imageBytes = await QRService.captureWidgetToImage(
        repaintBoundaryKey: _qrKey,
      );

      if (imageBytes == null) {
        _showMessage('Failed to capture QR code image', false);
        return;
      }

      final fileName = _generateFileName('png');
      final filePath = await QRService.exportAsPNG(
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (filePath != null) {
        _showMessage('PNG exported to Downloads: $fileName', true);
      } else {
        _showMessage('Failed to export PNG', false);
      }
    } catch (e) {
      _showMessage('Error: $e', false);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _exportAsPDF() async {
    if (_currentData.isEmpty) {
      _showMessage('Please enter data first', false);
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = null;
    });

    try {
      // Capture the QR widget as image
      final imageBytes = await QRService.captureWidgetToImage(
        repaintBoundaryKey: _qrKey,
      );

      if (imageBytes == null) {
        _showMessage('Failed to capture QR code image', false);
        return;
      }

      final fileName = _generateFileName('pdf');
      final filePath = await QRService.exportAsPDF(
        imageBytes: imageBytes,
        fileName: fileName,
        data: _currentData,
        title: _title ?? 'QR Code',
        description: 'Generated by SSS System',
      );

      if (filePath != null) {
        _showMessage('PDF exported to Downloads: $fileName', true);
      } else {
        _showMessage('Failed to export PDF', false);
      }
    } catch (e) {
      _showMessage('Error: $e', false);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _shareFile(String extension) async {
    if (_currentData.isEmpty) {
      _showMessage('Please enter data first', false);
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = null;
    });

    try {
      // Capture the QR widget as image
      final imageBytes = await QRService.captureWidgetToImage(
        repaintBoundaryKey: _qrKey,
      );

      if (imageBytes == null) {
        _showMessage('Failed to capture QR code image', false);
        return;
      }

      final fileName = _generateFileName(extension);
      String? filePath;

      if (extension == 'png') {
        filePath = await QRService.exportAsPNG(
          imageBytes: imageBytes,
          fileName: fileName,
        );
      } else {
        filePath = await QRService.exportAsPDF(
          imageBytes: imageBytes,
          fileName: fileName,
          data: _currentData,
          title: _title ?? 'QR Code',
          description: 'Generated by SSS System',
        );
      }

      if (filePath != null) {
        final success = await QRService.shareFile(
          filePath: filePath,
          subject: 'QR Code from SSS',
          text: 'QR Code generated by SSS System',
        );

        if (success) {
          _showMessage('Share sheet opened', true);
        } else {
          _showMessage('Failed to open share sheet', false);
        }
      } else {
        _showMessage('Failed to create file for sharing', false);
      }
    } catch (e) {
      _showMessage('Error: $e', false);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _verifyQR() {
    if (_currentData.isEmpty) {
      _showMessage('Please generate a QR code first', false);
      return;
    }

    final deepLink = QRService.generateDeepLink(
      data: _currentData,
      customIdentifier: _embeddedIdentifier,
      category: _title,
    );
    final isValid = QRData.isSystemDeepLink(deepLink);

    _showMessage(
      isValid 
          ? '✓ QR Code verified - Created by SSS System'
          : '✗ QR Code verification failed',
      isValid,
    );
  }

  void _showMessage(String message, bool isSuccess) {
    setState(() {
      _statusMessage = message;
      _isSuccess = isSuccess;
    });

    // Clear message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  Widget _buildQRWidget() {
    if (_currentData.isEmpty) {
      return Container(
        width: 250,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Enter data to generate QR code',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Generate deep link for the QR
    final deepLink = QRService.generateDeepLink(
      data: _currentData,
      customIdentifier: _embeddedIdentifier,
      category: _title,
    );

    return RepaintBoundary(
      key: _qrKey,
      child: BrandedQRCard(
        data: deepLink,
        title: _title,
        embeddedIdentifier: _embeddedIdentifier,
        qrSize: 200,
        foregroundColor: _selectedTheme.foreground,
        backgroundColor: _selectedTheme.background,
        roundedBorder: _roundedBorder,
        borderWidth: 2.0,
        borderColor: _selectedTheme.foreground.withOpacity(0.3),
        padding: 16.0,
        showIcon: true,
        iconColor: _selectedTheme.foreground,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title/Category input
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Title/Category (Optional)',
                  hintText: 'Enter a title or category',
                  border: OutlineInputBorder(),
                  helperText: 'This will appear above the QR code',
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_dataFocusNode);
                },
              ),
              const SizedBox(height: 16),

              // Data input
              TextField(
                controller: _dataController,
                focusNode: _dataFocusNode,
                decoration: const InputDecoration(
                  labelText: 'QR Code Data',
                  hintText: 'Enter data to encode',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_identifierFocusNode);
                },
              ),
              const SizedBox(height: 16),

              // Embedded identifier input (letter or emoji)
              TextField(
                controller: _identifierController,
                focusNode: _identifierFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Letter or Emoji (Optional)',
                  hintText: 'Enter a letter or emoji',
                  border: OutlineInputBorder(),
                  helperText: 'Add a letter or emoji in the center for uniqueness',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  _generateQR();
                },
              ),
              const SizedBox(height: 16),

              // Color theme selection
              const Text(
                'Color Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: QRColorTheme.presets.map((theme) {
                  final isSelected = theme == _selectedTheme;
                  return ChoiceChip(
                    label: Text(theme.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTheme = theme;
                        });
                      }
                    },
                    selectedColor: theme.background,
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Border style toggle
              Row(
                children: [
                  const Text(
                    'Border Style: ',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  ToggleButtons(
                    isSelected: [_roundedBorder, !_roundedBorder],
                    onPressed: (index) {
                      setState(() {
                        _roundedBorder = index == 0;
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Rounded'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Square'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Generate and Scan buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateQR,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generate QR Code'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _navigateToScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // QR Code preview
              Center(
                child: _buildQRWidget(),
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

              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isGenerating || _currentData.isEmpty
                        ? null
                        : _exportAsPNG,
                    icon: const Icon(Icons.image),
                    label: const Text('Export PNG'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isGenerating || _currentData.isEmpty
                        ? null
                        : _exportAsPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isGenerating || _currentData.isEmpty
                        ? null
                        : () => _shareFile('png'),
                    icon: const Icon(Icons.share),
                    label: const Text('Share PNG'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isGenerating || _currentData.isEmpty
                        ? null
                        : () => _shareFile('pdf'),
                    icon: const Icon(Icons.share),
                    label: const Text('Share PDF'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isGenerating || _currentData.isEmpty
                        ? null
                        : _verifyQR,
                    icon: const Icon(Icons.verified),
                    label: const Text('Verify QR'),
                  ),
                ],
              ),

              if (_isGenerating)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              const SizedBox(height: 24),

              // Info section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('System ID: ${QRData.systemId}'),
                      Text('Version: ${QRData.version}'),
                      const SizedBox(height: 8),
                      const Text(
                        'All QR codes generated by this system include a system identifier and deep link support.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
