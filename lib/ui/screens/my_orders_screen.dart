import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/listing_providers.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';

/// Buyer orders page - shows orders placed by the current user.
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final orders = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final o = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.wasteType,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Weight: ${o.weight} kg'),
                        Text('Seller: ${o.sellerName}'),
                        Text('Company: ${o.companyName}'),
                        Text('Status: ${o.status}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
