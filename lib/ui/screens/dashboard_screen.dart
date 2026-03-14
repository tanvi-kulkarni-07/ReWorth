import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/auth_provider.dart';
import '../shared_ui.dart';
import 'upload_waste_screen.dart';
import 'my_listings_screen.dart';
import 'marketplace_screen.dart';
import 'logistics_screen.dart';
import 'pickup_requests_screen.dart';
import 'my_orders_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showAllInsights = false;
  late final PageController _headerCarouselController;
  Timer? _carouselTimer;
  int _currentHeaderImage = 0;

  static const List<String> _headerImages = [
    'assets/img1.jpg',
    'assets/img2.jpg',
    'assets/img3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _headerCarouselController = PageController(viewportFraction: 1);
    _startCarouselAutoPlay();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _headerCarouselController.dispose();
    super.dispose();
  }

  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_headerCarouselController.hasClients) return;

      final nextPage = (_currentHeaderImage + 1) % _headerImages.length;
      _headerCarouselController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(realTimeAISuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF0091EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ReWorthUI.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: _buildDashboardContent(suggestionsAsync),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
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
                    color: Colors.white.withValues(alpha: 0.8),
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
                _buildHeaderCarousel(),
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
                  child: Builder(
                    builder: (context) {
                      final role = ref.watch(userRoleProvider);
                      final actions = <Widget>[];

                      if (role == 'seller') {
                        actions.addAll([
                          _buildQuickAction(
                            'Upload',
                            Icons.add_a_photo,
                            ReWorthUI.accentGreen,
                            () =>
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => const UploadWasteScreen(),
                                  ),
                                ),
                          ),
                          _buildQuickAction(
                            'Listings',
                            Icons.inventory_2,
                            Colors.blue,
                            () =>
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MyListingsScreen(),
                                  ),
                                ),
                          ),
                          _buildQuickAction(
                            'Requests',
                            Icons.local_shipping,
                            Colors.purple,
                            () =>
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PickupRequestsScreen(),
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
                            () =>
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MarketplaceScreen(),
                                  ),
                                ),
                          ),
                          _buildQuickAction(
                            'Logistics',
                            Icons.local_shipping,
                            Colors.blue,
                            () =>
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LogisticsScreen(),
                                  ),
                                ),
                          ),
                          _buildQuickAction(
                            'Orders',
                            Icons.receipt_long,
                            Colors.orange,
                            () =>
                                Navigator.of(context, rootNavigator: true).push(
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
                    },
                  ),
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
                  data: (suggestionsList) {
                    final displayList = _showAllInsights
                        ? suggestionsList
                        : suggestionsList.take(3).toList();

                    return Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final item = displayList[index];
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
                        if (suggestionsList.length > 3)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showAllInsights = !_showAllInsights;
                              });
                            },
                            child: Text(
                              _showAllInsights ? 'Show less' : 'Show all',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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

  Widget _buildHeaderCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: PageView.builder(
                controller: _headerCarouselController,
                itemCount: _headerImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentHeaderImage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(_headerImages[index], fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.12),
                              Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _carouselTitle(index),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _carouselSubtitle(index),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _headerImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentHeaderImage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentHeaderImage == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _carouselTitle(int index) {
    switch (index) {
      case 0:
        return 'Turn Waste Into Value';
      case 1:
        return 'Track Every Green Move';
      default:
        return 'Build A Circular Future';
    }
  }

  String _carouselSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Upload smarter, price better, and keep your recyclable flow moving.';
      case 1:
        return 'See your impact story unfold with every listing, pickup, and sale.';
      default:
        return 'Connect recovery, logistics, and earnings in one sustainability hub.';
    }
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
