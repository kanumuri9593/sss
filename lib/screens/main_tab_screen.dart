import 'package:flutter/material.dart';
import 'qr_poc_screen.dart';
import 'nfc_tag_management_screen.dart';
import 'container_list_screen.dart';
import 'search_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
              icon: Icon(Icons.inventory_2),
              text: 'Containers',
            ),
            Tab(
              icon: Icon(Icons.search),
              text: 'Search',
            ),
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          ContainerListScreen(),
          SearchScreen(),
          QRPOCScreen(),
          NFCTagManagementScreen(),
        ],
      ),
    );
  }
}

