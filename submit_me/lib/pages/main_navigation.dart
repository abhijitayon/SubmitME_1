import 'package:flutter/material.dart';
import 'package:submit_me/pages/home_page.dart';
import 'package:submit_me/pages/my_asset.dart';
import 'package:submit_me/pages/public_assets.dart';
import 'package:submit_me/widgets/profile_drawer.dart';
import 'package:submit_me/widgets/upload_dialog.dart';

/// The main application container for SubmitME after successful authentication.
/// Features:
/// 1. Persistent Bottom Navigation Bar with 4 items (Home, My Assets, Public Assets, Profile).
/// 2. Switching tabs does NOT recreate page state (uses IndexedStack).
/// 3. Floating Action Button (+) opens the upload modal for notes/assignments/lab works.
/// 4. Tapping "Profile" opens the Profile Drawer from the RIGHT side (endDrawer).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // GlobalKey to programmatically control the Scaffold's endDrawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // GlobalKeys to trigger refreshes across tabs without heavy state libraries
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey<MyAssetsPageState> _myAssetsKey = GlobalKey<MyAssetsPageState>();
  final GlobalKey<PublicAssetsPageState> _publicAssetsKey = GlobalKey<PublicAssetsPageState>();

  // Current active tab index (0: Home, 1: My Assets, 2: Public Assets)
  int _currentIndex = 0;

  // The 3 persistent tab views
  late final List<Widget> _pages;

  // Tab Titles for the AppBar
  final List<String> _titles = const [
    'SubmitME — Home',
    'My Assets',
    'Public Assets',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: _homeKey),
      MyAssetsPage(
        key: _myAssetsKey,
        onAssetChanged: () {
          // Whenever an asset is deleted, immediately update Home upload count
          _homeKey.currentState?.refreshCount();
        },
      ),
      PublicAssetsPage(key: _publicAssetsKey),
    ];
  }

  void _onTabTapped(int index) {
    if (index == 3) {
      // The 4th item is "Profile". Per requirements, open the right-side drawer
      // instead of navigating away to a separate page.
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      // Switch active tab index
      setState(() {
        _currentIndex = index;
      });
    }
  }

  /// Opens the upload modal dialog and refreshes views upon successful upload
  Future<void> _onUploadPressed() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UploadDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset uploaded successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Refresh Home upload count and both asset lists immediately
      _homeKey.currentState?.refreshCount();
      _myAssetsKey.currentState?.refreshList();
      _publicAssetsKey.currentState?.refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Quick button to open the Profile drawer from the right
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),

      // Right-side Profile Drawer
      endDrawer: const ProfileDrawer(),

      // IndexedStack preserves the state of Home, My Assets, and Public Assets
      // so switching tabs does not destroy or refetch them unnecessarily
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // Floating Action Button (+) for uploading assets
      floatingActionButton: FloatingActionButton(
        tooltip: 'Upload Asset',
        backgroundColor: const Color.fromARGB(255, 70, 136, 216),
        foregroundColor: Colors.white,
        onPressed: _onUploadPressed,
        child: const Icon(Icons.add, size: 28),
      ),

      // Persistent Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 70, 136, 216),
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'My Assets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: 'Public Assets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
