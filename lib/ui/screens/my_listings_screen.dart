import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_providers.dart';

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

    final listings = ref.watch(listingsProvider);
    final seller = ref.watch(userNameProvider) ?? '';
    final mine = listings.where((l) => l.sellerName == seller).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
      ),
      body: mine.isEmpty
          ? const Center(
              child: Text('No listings yet', style: TextStyle(fontSize: 18)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mine.length,
              itemBuilder: (context, idx) {
                final l = mine[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.wasteType,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Weight: ${l.weightKg} kg'),
                        Text('Company: ${l.companyName}'),
                        Text('Status: ${l.status}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
