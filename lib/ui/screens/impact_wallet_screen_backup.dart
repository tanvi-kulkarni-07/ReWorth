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

  // Helper method to get daily data for the past 7 days
  List<Map<String, double>> _calculateDailySellerData(List<WasteListing> soldListings) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    
    // Initialize with zeros for each day
    final dailyData = List.generate(7, (index) => {
      'co2': 0.0,
      'credits': 0.0,
    });

    for (final listing in soldListings) {
      if (listing.requestAcceptedAt != null) {
        final acceptedDate = listing.requestAcceptedAt!;
        final dayIndex = acceptedDate.difference(weekAgo).inDays;
        
        if (dayIndex >= 0 && dayIndex < 7) {
          final weight = listing.weightKg;
          final creditsEarned = weight * _carbonCreditsForWasteType(listing.wasteType);
          dailyData[dayIndex]['co2'] = (dailyData[dayIndex]['co2'] ?? 0) + weight;
          dailyData[dayIndex]['credits'] = (dailyData[dayIndex]['credits'] ?? 0) + creditsEarned;
        }
      }
    }

    return dailyData;
  }

  // Helper method to get monthly data for the past 6 months
  List<Map<String, double>> _calculateMonthlyBuyerData(List<Order> acceptedOrders) {
    final now = DateTime.now();
    
    // Initialize with zeros for each month
    final monthlyData = List.generate(6, (index) => {
      'co2': 0.0,
      'credits': 0.0,
    });

    for (final order in acceptedOrders) {
      if (order.acceptedAt != null) {
        final acceptedDate = order.acceptedAt!;
        
        // Calculate month index (0-5 for past 6 months)
        final monthsDiff = (now.year - acceptedDate.year) * 12 + (now.month - acceptedDate.month);
        
        if (monthsDiff >= 0 && monthsDiff < 6) {
          final weight = order.weight;
          final creditsEarned = weight * _carbonCreditsForWasteType(order.wasteType);
          monthlyData[monthsDiff]['co2'] = (monthlyData[monthsDiff]['co2'] ?? 0) + weight;
          monthlyData[monthsDiff]['credits'] = (monthlyData[monthsDiff]['credits'] ?? 0) + creditsEarned;
        }
      }
    }

    return monthlyData;
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
      
      // Carbon credits = sum of (weight * credits per kg for waste type)
      final carbonCredits = soldListings.fold<double>(0, (prev, listing) => 
        prev + (listing.weightKg * _carbonCreditsForWasteType(listing.wasteType)));
      
      // CO₂ reduction = quantity recycled (positive value showing reduction)
      final totalCo2Reduction = carbonCredits;
      
      return _buildSellerImpactWallet(context, carbonCredits, totalCo2Reduction, totalWasteSoldKg, userName, soldListings);
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

      // Carbon credits = sum of (weight * credits per kg for waste type)
      final carbonCredits = acceptedOrders.fold<double>(0, (prev, order) => 
        prev + (order.weight * _carbonCreditsForWasteType(order.wasteType)));

      // CO₂ impact decreases as more waste is recycled (negative value or reduction)
      final totalCo2Impact = -carbonCredits; // Negative to show reduction
      
      return _buildBuyerImpactWallet(context, carbonCredits, totalCo2Impact, totalWasteKg, userName, acceptedOrders);
    }
  }

  Widget _buildSellerImpactWallet(BuildContext context, double carbonCredits, double totalCo2Reduction, double totalWasteSoldKg, String userName, List<WasteListing> soldListings) {
    final dailyData = _calculateDailySellerData(soldListings);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Seller Hero Section - Business Focused
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '💰',
                              style: TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Revenue Generated',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${(carbonCredits * 25).toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Earned',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${totalWasteSoldKg.toStringAsFixed(0)} kg Waste Sold',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Seller Impact Metrics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSellerMetricCard(
                          'Carbon Credits',
                          carbonCredits.toStringAsFixed(0),
                          Icons.stars,
                          const Color(0xFFFFA726),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSellerMetricCard(
                          'CO₂ Saved',
                          '${(totalCo2Reduction / 1000).toStringAsFixed(1)}t',
                          Icons.eco,
                          const Color(0xFF66BB6A),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Seller Performance Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bar_chart, color: Color(0xFF2E7D32), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Weekly Sales Performance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: dailyData.isNotEmpty
                                ? dailyData.map((d) => [d['co2'] ?? 0.0, d['credits'] ?? 0.0]).expand((e) => e).reduce((a, b) => a > b ? a : b) * 1.2
                                : 50.0,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipBgColor: const Color(0xFF2E7D32),
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    return BarTooltipItem(
                                      '${days[groupIndex]}\n${rod.toY.toStringAsFixed(1)} ${rodIndex == 0 ? 'kg' : 'credits'}',
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
                                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                      return Text(
                                        days[value.toInt()],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2E7D32),
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
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                              barGroups: List.generate(7, (index) {
                                final data = dailyData[index];
                                final co2Value = data['co2'] ?? 0.0;
                                final creditsValue = data['credits'] ?? 0.0;

                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: co2Value,
                                      color: const Color(0xFF66BB6A),
                                      width: 16,
                                    ),
                                    BarChartRodData(
                                      toY: creditsValue,
                                      color: const Color(0xFFFFA726),
                                      width: 16,
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF66BB6A),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text('Waste Sold (kg)', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            SizedBox(width: 20),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFA726),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text('Credits Earned', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Seller Achievements
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Achievements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSellerAchievementCard(
                              'Top Seller',
                              'Sold ${totalWasteSoldKg.toStringAsFixed(0)}kg waste',
                              Icons.emoji_events,
                              const Color(0xFFFFD700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSellerAchievementCard(
                              'Eco Warrior',
                              '${(totalCo2Reduction / 1000).toStringAsFixed(1)} tons CO₂ saved',
                              Icons.eco,
                              const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSellerAchievementCard(
                        'Revenue Champion',
                        'Earned ₹${(carbonCredits * 25).toStringAsFixed(0)} this month',
                        Icons.account_balance_wallet,
                        const Color(0xFF2196F3),
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                                maxY: dailyData.isNotEmpty 
                                  ? dailyData.map((d) => [d['co2'] ?? 0.0, d['credits'] ?? 0.0]).expand((e) => e).reduce((a, b) => a > b ? a : b) * 1.2
                                  : 50.0,
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
                                barGroups: List.generate(7, (index) {
                                  final data = dailyData[index];
                                  final co2Value = data['co2'] ?? 0.0;
                                  final creditsValue = data['credits'] ?? 0.0;
                                  final maxValue = [co2Value, creditsValue, 10.0].reduce((a, b) => a > b ? a : b);
                                  
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: co2Value,
                                        color: Colors.green,
                                        width: 16,
                                      ),
                                      BarChartRodData(
                                        toY: creditsValue,
                                        color: Colors.blue,
                                        width: 16,
                                      ),
                                    ],
                                  );
                                }),
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

  Widget _buildBuyerImpactWallet(BuildContext context, double carbonCredits, double totalCo2Impact, double totalWasteKg, String userName, List<Order> acceptedOrders) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eco Impact Wallet'),
      ),
      body: Center(
        child: Text('Buyer Wallet - Credits: $carbonCredits'),
      ),
    );
  }

  Widget _buildSellerMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerAchievementCard(String emoji, String title, String subtitle, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerImpactCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEcoAchievementCard(String emoji, String title, String subtitle, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityImpactItem(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerAchievementCard(String title, String subtitle, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
