import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/auth_provider.dart';
import '../shared_ui.dart';
import 'upload_waste_screen.dart';
import 'my_listings_screen.dart';
import 'market_insights_screen.dart';
import 'marketplace_screen.dart';
import 'logistics_screen.dart';
import 'pickup_requests_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final double waste = ref.watch(dashboardTotalWasteProvider).toDouble();
    final double carbon = ref.watch(dashboardCarbonSavedProvider).toDouble();
    final double earnings = ref.watch(dashboardEarningsProvider).toDouble();
    final suggestionsAsync = ref.watch(realTimeAISuggestionsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'ReWorth Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ReWorthUI.accentGreen,
        onPressed: () =>
            Navigator.of(context, rootNavigator: true).pushNamed('/chat'),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ReWorthUI.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: _buildDashboardContent(
            waste,
            carbon,
            earnings,
            suggestionsAsync,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    double waste,
    double carbon,
    double earnings,
    AsyncValue<List<Map<String, dynamic>>> suggestionsAsync,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  ref.watch(userNameProvider) ?? 'Eco Warrior',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Waste Collected',
                        waste.toString(),
                        'kg',
                        Icons.recycling,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Carbon Offset',
                        carbon.toString(),
                        'kg CO₂',
                        Icons.eco,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEarningsCard(earnings),
              ],
            ),
          ),

          // Main Content Area with White Background and Rounded Corners
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Builder(builder: (context) {
                    final role = ref.watch(userRoleProvider);
                    final actions = <Widget>[];

                    if (role == 'seller') {
                      actions.addAll([
                        _buildQuickAction(
                          'Upload',
                          Icons.add_a_photo,
                          ReWorthUI.accentGreen,
                          () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const UploadWasteScreen(),
                            ),
                          ),
                        ),
                        _buildQuickAction(
                          'Listings',
                          Icons.inventory_2,
                          Colors.blue,
                          () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const MyListingsScreen(),
                            ),
                          ),
                        ),
                        _buildQuickAction(
                          'Requests',
                          Icons.local_shipping,
                          Colors.purple,
                          () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const PickupRequestsScreen(),
                            ),
                          ),
                        ),
                      ]);
                    } else {
                      actions.addAll([
                        _buildQuickAction(
                          'Marketplace',
                          Icons.storefront,
                          ReWorthUI.accentGreen,
                          () => Navigator.of(context, rootNavigator: true)
                              .push(MaterialPageRoute(
                            builder: (_) => const MarketplaceScreen(),
                          )),
                        ),
                        _buildQuickAction(
                          'Logistics',
                          Icons.local_shipping,
                          Colors.blue,
                          () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const LogisticsScreen(),
                            ),
                          ),
                        ),
                        _buildQuickAction(
                          'Orders',
                          Icons.receipt_long,
                          Colors.orange,
                          () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const MyOrdersScreen(),
                            ),
                          ),
                        ),
                      ]);
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: actions,
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // AI Insights
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Smart Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            ref.invalidate(realTimeAISuggestionsProvider),
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.grey,
                          size: 20,
                        ),
                        tooltip: 'Refresh AI Insights',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                suggestionsAsync.when(
                  data: (suggestionsList) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: suggestionsList.length,
                    itemBuilder: (context, index) {
                      final item = suggestionsList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAISuggestionCard(
                          item['text'] as String,
                          item['tag'] as String,
                          item['color'] as Color,
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Failed to load real-time insights.',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ReWorthUI.cardDecoration.copyWith(
        color: Colors.white.withOpacity(0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(double earnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ReWorthUI.cardDecoration.copyWith(
        color: Colors.white.withOpacity(0.15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Impact Earnings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '₹12,450.00',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAISuggestionCard(String text, String tag, Color tagColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_outline, color: tagColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tagColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A4A4A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[300]),
        ],
      ),
    );
  }
}
