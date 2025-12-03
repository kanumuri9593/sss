import 'package:flutter/material.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'qr_poc_screen.dart';
import 'nfc_poc_screen.dart';

/// Main Tab Screen with Liquid Glass Theme
/// 
/// Provides a tabbed interface with QR Code and NFC features
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSS - Search & Scan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code),
              text: 'QR Code',
            ),
            Tab(
              icon: Icon(Icons.nfc),
              text: 'NFC',
            ),
          ],
        ),
      ),
      body: LiquidGlassContainer(
        config: const LiquidGlassConfig(),
        child: TabBarView(
          controller: _tabController,
          children: const [
            QRPOCScreen(),
            NFCPOCScreen(),
          ],
        ),
      ),
    );
  }
}

