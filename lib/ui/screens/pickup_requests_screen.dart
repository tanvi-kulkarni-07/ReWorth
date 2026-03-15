import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_providers.dart';
import 'dashboard_screen.dart';

class PickupRequestsScreen extends ConsumerWidget {
  const PickupRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    if (role != 'seller') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => DashboardScreen()));
      });
      return const SizedBox.shrink();
    }

    final sellerId = ref.watch(userIdProvider);
    final sellerName = ref.watch(userNameProvider) ?? '';

    // Ensure we have a stable local user id before querying Firestore.
    if (sellerId == null || sellerId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final statusStages = ['pending', 'accepted', 'in_transit', 'completed'];

    final stageLabels = {
      'pending': 'Order Pending',
      'accepted': 'Accepted by Company',
      'in_transit': 'In Transit',
      'completed': 'Completed',
    };

    final requestsStream = FirebaseFirestore.instance
        .collection('pickup_requests')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt'.trim(), descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Requests'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorText = snapshot.error.toString();
            final indexUrl = _extractIndexUrl(errorText);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to load requests.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorText,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    if (indexUrl != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (await canLaunchUrlString(indexUrl)) {
                            await launchUrlString(indexUrl);
                          }
                        },
                        child: const Text('Create required Firestore index'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No pickup requests'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final request = PickupRequest.fromJson({
                ...data,
                'sellerId': data['sellerId'] ?? sellerId,
                'sellerName': data['sellerName'] ?? sellerName,
              });
              final currentStageIndex = statusStages.indexOf(
                request.status.toLowerCase(),
              );
              final currentStage = currentStageIndex >= 0
                  ? statusStages[currentStageIndex]
                  : statusStages.first;
              final stages = statusStages;

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
                          Text(
                            request.wasteType,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Company: ${request.companyName}'),
                          Text(
                            'Status: ${stageLabels[request.status.toLowerCase()] ?? request.status}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pickup Tracking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: stages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stage = entry.value;
                      final isCompleted = idx < currentStageIndex;
                      final isCurrent = idx == currentStageIndex;
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
                                stageLabels[stage] ?? stage,
                                style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
                  if (currentStageIndex < stages.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          final nextStatus = stages[currentStageIndex + 1];
                          FirebaseFirestore.instance
                              .collection('pickup_requests')
                              .doc(doc.id)
                              .update({'status': nextStatus});
                        },
                        child: Text(
                          'Advance to "${stageLabels[stages[currentStageIndex + 1]]}"',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String? _extractIndexUrl(String text) {
    const marker = 'https://console.firebase.google.com/';
    final idx = text.indexOf(marker);
    if (idx < 0) return null;
    final end = text.indexOf(' ', idx);
    return end < 0 ? text.substring(idx) : text.substring(idx, end);
  }
}
