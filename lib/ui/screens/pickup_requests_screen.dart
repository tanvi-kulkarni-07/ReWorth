import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/order_data.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class PickupRequestsScreen extends ConsumerWidget {
  const PickupRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    if (role != 'seller') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    final seller = ref.watch(userNameProvider) ?? '';
    final confirmedOrders = orders
        .where((o) => o['sellerName'] == seller && (o['status'] ?? '') == 'Confirmed')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Requests'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
      ),
      body: confirmedOrders.isEmpty
          ? const Center(child: Text('No pickup requests'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: confirmedOrders.length,
              itemBuilder: (context, index) {
                final order = confirmedOrders[index];
                final hasPickupSchedule = (order['pickupDate'] ?? '').toString().isNotEmpty;
                final currentStage = hasPickupSchedule ? 'Pickup Scheduled' : 'Order Confirmed';
                final stages = [
                  'Order Confirmed',
                  'Pickup Scheduled',
                  'Truck Dispatched',
                  'Waste Collected',
                  'Delivered to Recycling Plant',
                ];
                final currentIndex = stages.indexOf(currentStage);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order['wasteType'] ?? '',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Company: ${order['companyName'] ?? ''}'),
                            Text('Pickup Location: ${order['location'] ?? ''}'),
                            Text('Pickup Date: ${order['pickupDate'] ?? ''}'),
                            Text('Pickup Time: ${order['pickupTime'] ?? ''}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Pickup Tracking',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: stages.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final stage = entry.value;
                        final isCompleted = idx < currentIndex;
                        final isCurrent = idx == currentIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : isCurrent
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                color: isCompleted
                                    ? Colors.green
                                    : isCurrent
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  stage,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isCompleted
                                        ? Colors.green
                                        : isCurrent
                                            ? Colors.blue
                                            : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
    );
  }
}
