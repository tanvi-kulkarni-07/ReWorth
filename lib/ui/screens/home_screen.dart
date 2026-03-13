import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'marketplace_screen.dart';
import 'logistics_screen.dart';
import 'impact_wallet_screen.dart';
import 'profile_screen.dart';
import 'upload_waste_screen.dart';
import 'my_listings_screen.dart';
import 'my_orders_screen.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PersistentTabController _controller;
  String? _lastRole;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _buildScreens(String? role) {
    if (role == 'seller') {
      return const [
        DashboardScreen(),
        UploadWasteScreen(),
        MyListingsScreen(),
        ImpactWalletScreen(), // earnings
        ProfileScreen(),
      ];
    }
    // default to buyer (or null) - include orders and wallet separately
    return const [
      DashboardScreen(),
      MarketplaceScreen(),
      LogisticsScreen(),
      MyOrdersScreen(),
      ImpactWalletScreen(),
      ProfileScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems(String? role) {
    if (role == 'seller') {
      return [
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.dashboard),
          title: "Dashboard",
          activeColorPrimary: const Color(0xFF00A699),
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.add_a_photo),
          title: "Upload",
          activeColorPrimary: const Color(0xFF00A699),
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.inventory_2),
          title: "Listings",
          activeColorPrimary: const Color(0xFF00A699),
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.account_balance_wallet),
          title: "Earnings",
          activeColorPrimary: const Color(0xFF00A699),
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.person),
          title: "Profile",
          activeColorPrimary: const Color(0xFF00A699),
          inactiveColorPrimary: Colors.grey,
        ),
      ];
    }
    // buyer
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.dashboard),
        title: "Dashboard",
        activeColorPrimary: const Color(0xFF00A699),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.storefront),
        title: "Marketplace",
        activeColorPrimary: const Color(0xFF00A699),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.local_shipping),
        title: "Logistics",
        activeColorPrimary: const Color(0xFF00A699),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.receipt_long),
        title: "Orders",
        activeColorPrimary: const Color(0xFF00A699),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.account_balance_wallet),
        title: "Wallet",
        activeColorPrimary: const Color(0xFF00A699),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: "Profile",
        activeColorPrimary: const Color(0xFF00A699),
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final role = ref.watch(userRoleProvider);
      final screens = _buildScreens(role);
      final items = _navBarsItems(role);

      // If the role changed (and thus the number of tabs), reset the controller.
      if (role != _lastRole) {
        _lastRole = role;
        _controller = PersistentTabController(initialIndex: 0);
      }

      return PersistentTabView(
        context,
        controller: _controller,
        screens: screens,
        items: items,
        confineToSafeArea: true,
        backgroundColor: Colors.white,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,
        navBarStyle: NavBarStyle.style1,
        // optional height settings
        navBarHeight: 60,
        // animation settings (default is fine)
        animationSettings: const NavBarAnimationSettings(
          screenTransitionAnimation: ScreenTransitionAnimationSettings(
            animateTabTransition: true,
            duration: Duration(milliseconds: 200),
            curve: Curves.ease,
          ),
        ),
      );
    });
  }
}
