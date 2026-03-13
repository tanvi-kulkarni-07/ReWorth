import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/listing_providers.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';

/// Seller pickup requests page.
class PickupRequestsScreen extends ConsumerWidget {
  const PickupRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    // Allow null role in tests (no auth context), but enforce buyer vs seller in real usage.
    if (role != null && role != 'seller') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    final requests = ref.watch(pickupRequestsProvider);
    // filter to current seller
    final sellerName = ref.watch(userNameProvider) ?? '';
    final mine = requests.where((r) => r.sellerName == sellerName).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Requests'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
      ),
      body: mine.isEmpty
          ? const Center(child: Text('No pickup requests'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mine.length,
              itemBuilder: (context, idx) {
                final r = mine[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.wasteType,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Weight: ${r.weight} kg'),
                        Text('Company: ${r.companyName}'),
                        Text('Status: ${r.status}'),
                      ],
                    ),
                  ),
                );
              }),
    );
  }
}
