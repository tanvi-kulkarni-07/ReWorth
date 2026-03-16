import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'logistics_screen.dart';
import 'impact_wallet_screen.dart';
import 'profile_screen.dart';
import 'my_listings_screen.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String? _lastRole;

  List<Widget> _buildScreens(String? role) {
    if (role == 'seller') {
      return const [
        DashboardScreen(),
        LogisticsScreen(),
        MyListingsScreen(),
        ImpactWalletScreen(), // earnings
        ProfilePage(),
      ];
    }
    // default to buyer (or null) - keep only the core buyer tabs
    return const [DashboardScreen(), ImpactWalletScreen(), ProfilePage()];
  }

  List<NavigationDestination> _navBarDestinations(String? role) {
    if (role == 'seller') {
      return const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping),
          label: 'Logistics',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Listings',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Earnings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
    return const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Wallet',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final role = ref.watch(userRoleProvider);
        final screens = _buildScreens(role);
        final destinations = _navBarDestinations(role);

        if (role != _lastRole) {
          _lastRole = role;
          _currentIndex = 0;
        }

        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          extendBody: true, // Allow body to flow under the navbar if needed
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: const Color(0xFF00A699).withOpacity(0.16),
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                states,
              ) {
                final isSelected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF00A699) : Colors.grey,
                );
              }),
            ),
            child: NavigationBar(
              backgroundColor: Colors.white,
              selectedIndex: _currentIndex,
              destinations: destinations,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        );
      },
    );
  }
}
