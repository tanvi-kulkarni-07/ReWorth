import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
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

    final companyName = ref.watch(userNameProvider) ?? '';
    final statusStages = ['pending', 'accepted', 'in_transit', 'completed'];
    final stageLabels = {
      'pending': 'Pending',
      'accepted': 'Accepted',
      'in_transit': 'In Transit',
      'completed': 'Completed',
    };

    final requestsStream = FirebaseFirestore.instance
        .collection('pickup_requests')
        .where('companyName', isEqualTo: companyName)
        .orderBy('createdAt'.trim(), descending: true)
        .snapshots();

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No orders yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final status =
                  (data['status'] as String?)?.toLowerCase() ?? 'pending';
              final currentStageIndex = statusStages.indexOf(status);
              final canAdvance =
                  currentStageIndex >= 0 &&
                  currentStageIndex < statusStages.length - 1;
              final nextStage = canAdvance
                  ? statusStages[currentStageIndex + 1]
                  : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['wasteType'] as String? ?? 'Unknown waste',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Seller: ${data['sellerName'] ?? 'Unknown'}'),
                      Text('Weight: ${data['weight'] ?? '-'} kg'),
                      Text('Status: ${stageLabels[status] ?? status}'),
                      const SizedBox(height: 12),
                      if (canAdvance && nextStage != null)
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('pickup_requests')
                                .doc(doc.id)
                                .update({'status': nextStage});
                          },
                          child: Text(
                            'Mark as ${stageLabels[nextStage] ?? nextStage}',
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
