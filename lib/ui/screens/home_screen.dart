import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'marketplace_screen.dart';
import 'logistics_screen.dart';
import 'impact_wallet_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
//
class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // Use IndexedStack to preserve state but prevent rebuilds of invisible screens
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Marketplace'),
    BottomNavigationBarItem(
      icon: Icon(Icons.local_shipping),
      label: 'Logistics',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet),
      label: 'Wallet',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardScreen(),
          MarketplaceScreen(),
          LogisticsScreen(),
          ImpactWalletScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF00A699),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}
