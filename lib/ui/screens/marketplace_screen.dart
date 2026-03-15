import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/listing_providers.dart';
import '../../providers/auth_provider.dart';
import 'waste_sellers_screen.dart';
import 'dashboard_screen.dart';

class WasteSummary {
  final String wasteType;
  final double totalKg;
  final double avgPricePerKg;
  final String recyclability;

  WasteSummary({
    required this.wasteType,
    required this.totalKg,
    required this.avgPricePerKg,
    required this.recyclability,
  });
}

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  List<WasteSummary> _buildSummary(List<WasteListing> listings) {
    if (listings.isEmpty) {
      return [
        WasteSummary(
          wasteType: 'Plastic',
          totalKg: 10000,
          avgPricePerKg: 20,
          recyclability: 'Recyclable',
        ),
        WasteSummary(
          wasteType: 'Metal',
          totalKg: 5000,
          avgPricePerKg: 25,
          recyclability: 'Recyclable',
        ),
        WasteSummary(
          wasteType: 'Paper',
          totalKg: 8000,
          avgPricePerKg: 10,
          recyclability: 'Recyclable',
        ),
        WasteSummary(
          wasteType: 'Glass',
          totalKg: 3000,
          avgPricePerKg: 12,
          recyclability: 'Recyclable',
        ),
        WasteSummary(
          wasteType: 'Agro Waste',
          totalKg: 20000,
          avgPricePerKg: 8,
          recyclability: 'Compostable',
        ),
      ];
    }

    final Map<String, _Agg> agg = {};
    for (final listing in listings) {
      final key = listing.wasteType;
      final entry = agg.putIfAbsent(key, () => _Agg());
      entry.totalKg += listing.weightKg;
      entry.totalValue += listing.pricePerKg * listing.weightKg;
    }

    return agg.entries.map((e) {
      final averagePrice = e.value.totalKg > 0
          ? e.value.totalValue / e.value.totalKg
          : 0.0;
      return WasteSummary(
        wasteType: e.key,
        totalKg: e.value.totalKg,
        avgPricePerKg: averagePrice,
        recyclability: _recyclabilityFor(e.key),
      );
    }).toList();
  }

  String _recyclabilityFor(String wasteType) {
    final lower = wasteType.toLowerCase();
    if (lower.contains('plastic') ||
        lower.contains('metal') ||
        lower.contains('paper') ||
        lower.contains('glass')) {
      return 'Recyclable';
    }
    if (lower.contains('agro') || lower.contains('organic')) {
      return 'Compostable';
    }
    return 'Recyclable';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    if (role != null && role != 'buyer') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    final listings = ref.watch(listingsProvider);
    final summaries = _buildSummary(listings);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Marketplace',
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final item = summaries[index];
            final availableTons = item.totalKg / 1000;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WasteSellersScreen(wasteType: item.wasteType),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.wasteType} Waste',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Available: ${availableTons.toStringAsFixed(1)} Tons'),
                      Text('Price: ₹${item.avgPricePerKg.toStringAsFixed(0)}/kg'),
                      Text('Recyclability: ${item.recyclability}'),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Agg {
  double totalKg = 0;
  double totalValue = 0;
}
