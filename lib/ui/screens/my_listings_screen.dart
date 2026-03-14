import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/order_data.dart';
import '../../providers/auth_provider.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    if (role != 'seller') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const SizedBox.shrink();
    }

    final seller = ref.watch(userNameProvider) ?? '';
    final myOrders = orders.where((o) => o['sellerName'] == seller).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Listings',
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
        child: myOrders.isEmpty
            ? const Center(
                child: Text(
                  'No listings yet',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myOrders.length,
                itemBuilder: (context, index) {
                  final order = myOrders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['wasteType'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Quantity: ${order['quantity'] ?? ''}'),
                          Text('Company: ${order['companyName'] ?? ''}'),
                          Text('Location: ${order['location'] ?? ''}'),
                          Text('Status: ${order['status'] ?? ''}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
