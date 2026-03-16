import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/listing_providers.dart';
import '../../providers/auth_provider.dart';
import 'sustainability_certificate_screen.dart';
import 'coupon_rewards_screen.dart';

class ImpactWalletScreen extends ConsumerWidget {
  const ImpactWalletScreen({super.key});

  double _carbonCreditsForWasteType(String wasteType) {
    final lower = wasteType.toLowerCase();
    if (lower.contains('plastic')) return 1.0;
    if (lower.contains('paper')) return 1.0;
    if (lower.contains('metal')) return 2.0;
    if (lower.contains('glass')) return 0.5;
    if (lower.contains('organic') || lower.contains('agro')) return 0.3;
    return 0.5;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    final userRole = ref.watch(userRoleProvider);
    final userName = ref.watch(userNameProvider) ?? '';
    
    if (userRole == 'seller') {
      // Seller Impact Wallet Logic
      final allListings = ref.watch(listingsProvider);
      final sellerListings = allListings.where((listing) => listing.sellerName == userName).toList();
      
      // Calculate sold waste (listings that have been accepted/picked up)
      final soldListings = sellerListings.where((listing) => 
        listing.status == 'pickup_started' || 
        listing.status == 'request_accepted' ||
        listing.status == 'company_selected'
      ).toList();
      
      final totalWasteSoldKg = soldListings.fold<double>(0, (prev, listing) => prev + listing.weightKg);
      
      // Carbon credits = quantity sold (1:1 ratio with weight in kg)
      final carbonCredits = totalWasteSoldKg;
      
      // CO₂ reduction = quantity recycled (positive value showing reduction)
      final totalCo2Reduction = carbonCredits;
      
      return _buildSellerImpactWallet(context, carbonCredits, totalCo2Reduction, totalWasteSoldKg, userName);
    } else {
      // Buyer Impact Wallet Logic (existing)
      final allOrders = ref.watch(ordersProvider);
      
      // Filter orders to only show those purchased by the current user
      final orders = userId != null 
          ? allOrders.where((order) => order.buyerId == userId).toList()
          : allOrders; // Fallback to all orders if no user ID
      
      // Only count accepted orders for carbon credits
      final acceptedOrders = orders.where((o) => o.status == 'accepted').toList();
      final totalWasteKg = acceptedOrders.fold<double>(0, (prev, o) => prev + o.weight);

      // Carbon credits = quantity purchased (1:1 ratio with weight in kg)
      final carbonCredits = totalWasteKg;

      // CO₂ impact decreases as more waste is recycled (negative value or reduction)
      final totalCo2Impact = -carbonCredits; // Negative to show reduction
      
      return _buildBuyerImpactWallet(context, carbonCredits, totalCo2Impact, totalWasteKg, userName);
    }
  }

  Widget _buildSellerImpactWallet(BuildContext context, double carbonCredits, double totalCo2Reduction, double totalWasteSoldKg, String userName) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Impact Wallet',
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
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Premium Hero Card with Gradient
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00A699),
                      Color(0xFF00C9B7),
                      Color(0xFF008B7D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A699).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🌱',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Carbon Credits Earned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          carbonCredits.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Credits',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Total Waste Sold: ${totalWasteSoldKg.toStringAsFixed(0)} kg',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Seller Impact Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Impact Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your impact at a glance: earnings, waste recycled, and CO₂ savings.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildImpactSummaryItem(
                            Colors.green.shade600,
                            'Waste Sold',
                            '${totalWasteSoldKg.toStringAsFixed(0)} kg',
                            Icons.sell,
                          ),
                          _buildImpactSummaryItem(
                            Colors.blue.shade600,
                            'Credits Earned',
                            carbonCredits.toStringAsFixed(0),
                            Icons.stars,
                          ),
                          _buildImpactSummaryItem(
                            Colors.orange.shade600,
                            'CO₂ Saved',
                            '${(totalCo2Reduction / 1000).toStringAsFixed(1)} t',
                            Icons.eco,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Daily Environmental Impact (Weekly View)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Environmental Impact',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your daily CO₂ reduction and carbon credits earned this week',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Weekly Chart Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Legend
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CO₂ Reduced (kg)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Carbon Credits Earned',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Weekly Bar Chart
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 50, // Adjust based on max daily values
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      String weekDay = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][groupIndex];
                                      return BarTooltipItem(
                                        '$weekDay\n${rod.toY.toStringAsFixed(1)} ${rodIndex == 0 ? 'kg CO₂' : 'credits'}',
                                        const TextStyle(color: Colors.white),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                        return Text(
                                          days[value.toInt()],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 10,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.withOpacity(0.2),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: [
                                  // Sample daily data for the week
                                  // Monday
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: 12.5, // CO₂ reduced in kg
                                        color: Colors.green,
                                        width: 16,
                                      ),
                                      BarChartRodData(
                                        toY: 12.5, // Carbon credits earned
                                        color: Colors.blue,
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                  // Tuesday
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: 18.3,
                                        color: Colors.green,
                                        width: 16,
                                      ),
                                      BarChartRodData(
                                        toY: 18.3,
                                        color: Colors.blue,
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                  // Wednesday
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: 15.7,
                                        color: Colors.green,
                                        width: 16,
                                      ),
                                      BarChartRodData(
                                        toY: 15.7,
                                        color: Colors.blue,
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                  // Thursday
                                  BarChartGroupData(
                                    x: 3,
                                    barRods: [
                                      BarChartRodData(
                                        toY: 22.1,
                                        color: Colors.green,
                                        width: 16,
                                      ),
                                      BarChartRodData(
                                        toY: 22.1,
                                        color: Colors.blue,
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                  // Friday
                                  BarChartGroupData(
                                    x: 4,
                                    barRods: [
                                      BarChartRodData(
                                        toY: 19.8,
                                        color: Colors.green,
                                        width: 16,
                                      ),
                                      BarChartRodData(
                                        toY: 19.8,
                                        color: Colors.blue,
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                  // Saturday
                                  BarChartGroupData(
                                    x: 5,
                                    barRods: [
                                      BarChartRodData(
                                        toY: 8.4,
                                        color: Colors.green,
                                        width: 16,
                                      ),
                                      BarChartRodData(
                                        toY: 8.4,
                                        color: Colors.blue,
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                  // Sunday
                                  BarChartGroupData(
                                    x: 6,
                                    barRods: [
                                      BarChartRodData(
                                        toY: 6.2,
                                        color: Colors.green,
                                        width: 16,
                                      ),
                                      BarChartRodData(
                                        toY: 6.2,
                                        color: Colors.blue,
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Impact Breakdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Impact Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildImpactBreakdownItem(
                      'Waste Sold',
                      '${totalWasteSoldKg.toStringAsFixed(0)} kg',
                      totalWasteSoldKg > 0 ? 1.0 : 0.0,
                      Colors.green,
                      Icons.sell,
                    ),
                    _buildImpactBreakdownItem(
                      'Carbon Credits',
                      carbonCredits.toStringAsFixed(0),
                      carbonCredits > 0 ? 1.0 : 0.0,
                      Colors.blue,
                      Icons.stars,
                    ),
                    _buildImpactBreakdownItem(
                      'CO₂ Reduction',
                      '${(totalCo2Reduction / 1000).toStringAsFixed(1)} tons',
                      totalCo2Reduction > 0 ? 1.0 : 0.0,
                      Colors.orange,
                      Icons.eco,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Achievements Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Achievements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Green Champion Certificate Badge
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SustainabilityCertificateScreen(
                                    sellerName: userName,
                                    wasteQuantity: totalWasteSoldKg,
                                    co2Saved: totalCo2Reduction,
                                    carbonCredits: carbonCredits,
                                    sustainabilityScore: 95.0,
                                  ),
                                ),
                              );
                            },
                            child: _buildAchievementBadge(
                              '📜',
                              'Green Champion',
                              'Sustainability Certificate',
                              Colors.green,
                            ),
                          ),
                          // Green Contributor - Show Coupon Rewards
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CouponRewardsScreen(
                                    sellerName: userName,
                                    wasteQuantity: totalWasteSoldKg,
                                    carbonCredits: carbonCredits,
                                  ),
                                ),
                              );
                            },
                            child: _buildAchievementBadge(
                              '💚',
                              'Green Contributor',
                              'Earn eco rewards',
                              Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerImpactWallet(BuildContext context, double carbonCredits, double totalCo2Impact, double totalWasteKg, String userName) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buyer Impact Wallet',
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
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Premium Hero Card with Gradient
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00A699),
                      Color(0xFF00C9B7),
                      Color(0xFF008B7D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A699).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🌍',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Carbon Credits Earned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          carbonCredits.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Credits',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Total Waste Purchased: ${totalWasteKg.toStringAsFixed(0)} kg',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Carbon Credits Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Carbon Credits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You earn 1 carbon credit for every kilogram of waste you purchase. Credits accumulate automatically when your orders are completed.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Credits',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                carbonCredits.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00C853),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Waste Purchased',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${totalWasteKg.toStringAsFixed(0)} kg',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0091EA),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Monthly Impact Graph Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: const Text(
                            'Monthly Environmental Impact',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '2026',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Graph Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                Colors.green.shade400,
                                'CO₂ Saved',
                              ),
                              const SizedBox(width: 20),
                              _buildLegendItem(
                                Colors.blue.shade400,
                                'Credits Earned',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Bar Chart
                          SizedBox(
                            height: 200,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBarGroup('Jan', 120, 85),
                                _buildBarGroup('Feb', 150, 110),
                                _buildBarGroup('Mar', 180, 140),
                                _buildBarGroup('Apr', 210, 165),
                                _buildBarGroup('May', 195, 155),
                                _buildBarGroup('Jun', 240, 180),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Summary Stats
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  carbonCredits.toStringAsFixed(0),
                                  'Total Credits',
                                  Icons.stars,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.green.shade200,
                                ),
                                _buildSummaryItem(
                                  '${(-totalCo2Impact / 1000).toStringAsFixed(1)} tons',
                                  'CO₂ Reduced',
                                  Icons.eco,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.green.shade200,
                                ),
                                _buildSummaryItem(
                                  '62 Trees',
                                  'Equivalent',
                                  Icons.park,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Impact Breakdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Impact Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildImpactBreakdownItem(
                      'Waste Purchased',
                      '${totalWasteKg.toStringAsFixed(0)} kg',
                      totalWasteKg > 0 ? 1.0 : 0.0,
                      Colors.green,
                      Icons.shopping_cart,
                    ),
                    _buildImpactBreakdownItem(
                      'Carbon Credits',
                      carbonCredits.toStringAsFixed(0),
                      carbonCredits > 0 ? 1.0 : 0.0,
                      Colors.blue,
                      Icons.stars,
                    ),
                    _buildImpactBreakdownItem(
                      'CO₂ Impact',
                      '${(-totalCo2Impact / 1000).toStringAsFixed(1)} tons',
                      totalCo2Impact < 0 ? 1.0 : 0.0,
                      Colors.orange,
                      Icons.eco,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Achievements Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Achievements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Eco Buyer certificate
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SustainabilityCertificateScreen(
                                    sellerName: userName,
                                    wasteQuantity: totalWasteKg,
                                    co2Saved: totalWasteKg,
                                    carbonCredits: carbonCredits,
                                    sustainabilityScore: 90.0,
                                  ),
                                ),
                              );
                            },
                            child: _buildAchievementBadge(
                              '🏆',
                              'Eco Buyer',
                              'Purchased 100+ kg',
                              Colors.amber,
                            ),
                          ),

                          // Sustainability Partner coupon
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CouponRewardsScreen(
                                    sellerName: userName,
                                    wasteQuantity: totalWasteKg,
                                    carbonCredits: carbonCredits,
                                  ),
                                ),
                              );
                            },
                            child: _buildAchievementBadge(
                              '💚',
                              'Sustainability Partner',
                              'Get eco rewards',
                              Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String emoji,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBarGroup(String month, double greenHeight, double blueHeight) {
    const maxHeight = 168.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 14,
              height: (greenHeight / 240) * maxHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 14,
              height: (blueHeight / 240) * maxHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildImpactSummaryItem(
    Color color,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBreakdownItem(
    String title,
    String value,
    double progress,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(
    String emoji,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
