import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/listing_providers.dart';
import 'dashboard_screen.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    if (role != 'buyer') {
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
        title: const Text(
          'My Orders',
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
      body: orders.isEmpty
          ? const Center(
              child: Text(
                'No seller requests yet.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final accepted = order.status.toLowerCase() == 'accepted';
                final rejected = order.status.toLowerCase() == 'rejected';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.wasteType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Seller: ${order.sellerName}'),
                        Text('Quantity: ${(order.weight / 1000).toStringAsFixed(1)} tons'),
                        Text('Location: ${order.sellerLocation}'),
                        Text('Contact: ${order.contactPhone}'),
                        const SizedBox(height: 12),
                        if (!accepted && !rejected)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(ordersProvider.notifier)
                                        .updateOrderStatus(index, 'accepted');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A699),
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    ref
                                        .read(ordersProvider.notifier)
                                        .updateOrderStatus(index, 'rejected');
                                  },
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            accepted ? 'Accepted' : 'Rejected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: accepted ? Colors.green : Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
