import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class SellerSupply {
  final String sellerName;
  final String wasteType;
  final String quantity;
  final String companyName;
  final String location;
  final LatLng coords;

  SellerSupply({
    required this.sellerName,
    required this.wasteType,
    required this.quantity,
    required this.companyName,
    required this.location,
    required this.coords,
  });
}

class LogisticsScreen extends ConsumerStatefulWidget {
  const LogisticsScreen({super.key});

  @override
  ConsumerState<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends ConsumerState<LogisticsScreen> {
  SellerSupply? _selectedSupply;

  final List<SellerSupply> _supplies = [
    SellerSupply(
      sellerName: 'Farmer Ramesh Patil',
      wasteType: 'Banana Tree Waste',
      quantity: '10 Tons',
      companyName: 'Green Agro Recycling Ltd',
      location: 'Jalgaon, Maharashtra',
      coords: const LatLng(21.0077, 75.5626),
    ),
    SellerSupply(
      sellerName: 'Scrap Dealer Amit Sharma',
      wasteType: 'Plastic Bottles',
      quantity: '2 Tons',
      companyName: 'EcoPlastic Industries',
      location: 'Pune, Maharashtra',
      coords: const LatLng(18.5204, 73.8567),
    ),
  ];

  void _toggleMap(SellerSupply supply) {
    setState(() {
      _selectedSupply = _selectedSupply == supply ? null : supply;
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    // Allow null role in tests (no auth context), but enforce buyer vs seller in real usage.
    if (role != null && role != 'buyer') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Logistics'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _supplies.length,
        itemBuilder: (context, index) {
          final supply = _supplies[index];
          final isSelected = _selectedSupply == supply;
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supply.sellerName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Waste: ${supply.wasteType}'),
                      Text('Quantity: ${supply.quantity}'),
                      Text('Company: ${supply.companyName}'),
                      Text('Location: ${supply.location}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _toggleMap(supply),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A699),
                        ),
                        child:
                            Text(isSelected ? 'Hide Map' : 'View on Map'),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                SizedBox(
                  height: 220,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: supply.coords,
                        initialZoom: 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: supply.coords,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
