import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_providers.dart';
import 'dashboard_screen.dart';

class PickupRequestsScreen extends ConsumerStatefulWidget {
  const PickupRequestsScreen({super.key});

  @override
  ConsumerState<PickupRequestsScreen> createState() =>
      _PickupRequestsScreenState();
}

class _PickupRequestsScreenState extends ConsumerState<PickupRequestsScreen> {
  final Set<String> _autoAdvancingRequestIds = <String>{};

  void _scheduleAutoAdvance({
    required String requestId,
    required List<String> stages,
  }) {
    if (_autoAdvancingRequestIds.contains(requestId)) return;
    _autoAdvancingRequestIds.add(requestId);

    Future.delayed(const Duration(seconds: 4), () async {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('pickup_requests')
            .doc(requestId);
        final snapshot = await docRef.get();
        if (!snapshot.exists) return;

        final data = snapshot.data();
        final currentStatus = (data?['status'] as String? ?? stages.first)
            .toLowerCase();
        final idx = stages.indexOf(currentStatus);
        if (idx >= 0 && idx < stages.length - 1) {
          await docRef.update({'status': stages[idx + 1]});
        }
      } finally {
        _autoAdvancingRequestIds.remove(requestId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
              final stages = statusStages;
              final safeStageIndex = currentStageIndex < 0
                  ? 0
                  : currentStageIndex;

              if (safeStageIndex < stages.length - 1) {
                _scheduleAutoAdvance(requestId: doc.id, stages: stages);
              }

              final companyPoint = LatLng(
                request.companyLat,
                request.companyLng,
              );
              final sellerPoint = LatLng(request.sellerLat, request.sellerLng);

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
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  (companyPoint.latitude +
                                          sellerPoint.latitude) /
                                      2,
                                  (companyPoint.longitude +
                                          sellerPoint.longitude) /
                                      2,
                                ),
                                initialZoom: 8.5,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.reworth',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: [companyPoint, sellerPoint],
                                      strokeWidth: 4,
                                      color: Colors.blueAccent,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: companyPoint,
                                      width: 36,
                                      height: 36,
                                      child: const Icon(
                                        Icons.location_city,
                                        color: Colors.blue,
                                        size: 28,
                                      ),
                                    ),
                                    Marker(
                                      point: sellerPoint,
                                      width: 36,
                                      height: 36,
                                      child: const Icon(
                                        Icons.home,
                                        color: Colors.green,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'From: ${request.companyName}  →  To: ${request.sellerName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final stepWidth = totalWidth / stages.length;
                      final trackLeft = stepWidth / 2;
                      final trackWidth = totalWidth - stepWidth;
                      final progress = stages.length <= 1
                          ? 1.0
                          : safeStageIndex / (stages.length - 1);

                      return SizedBox(
                        width: totalWidth,
                        height: 130,
                        child: Stack(
                          children: [
                            Positioned(
                              left: trackLeft,
                              right: trackLeft,
                              top: 24,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Positioned(
                              left: trackLeft,
                              top: 24,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeInOutCubic,
                                width: trackWidth * progress,
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00A699),
                                      const Color(0xFF17B57C),
                                      const Color(0xFF34D399),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00A699,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: stages.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final stage = entry.value;
                                    final isCompleted = idx < safeStageIndex;
                                    final isCurrent = idx == safeStageIndex;

                                    return Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            curve: Curves.elasticOut,
                                            width: isCurrent ? 36 : 32,
                                            height: isCurrent ? 36 : 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isCompleted
                                                  ? Colors.green.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : isCurrent
                                                  ? const Color(
                                                      0xFF00A699,
                                                    ).withValues(alpha: 0.15)
                                                  : Colors.grey.withValues(
                                                      alpha: 0.1,
                                                    ),
                                              border: Border.all(
                                                color: isCompleted
                                                    ? Colors.green
                                                    : isCurrent
                                                    ? const Color(0xFF00A699)
                                                    : Colors.grey.shade400,
                                                width: isCurrent ? 2.5 : 2,
                                              ),
                                              boxShadow:
                                                  isCompleted || isCurrent
                                                  ? [
                                                      BoxShadow(
                                                        color:
                                                            (isCompleted
                                                                    ? Colors
                                                                          .green
                                                                    : const Color(
                                                                        0xFF00A699,
                                                                      ))
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          3,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              child: Icon(
                                                isCompleted
                                                    ? Icons.check
                                                    : isCurrent
                                                    ? Icons.radio_button_checked
                                                    : Icons
                                                          .radio_button_unchecked,
                                                key: ValueKey<String>(
                                                  '${stage}_${isCompleted}_${isCurrent}',
                                                ),
                                                size: isCurrent ? 20 : 18,
                                                color: isCompleted
                                                    ? Colors.green
                                                    : isCurrent
                                                    ? const Color(0xFF00A699)
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            child: SizedBox(
                                              height: 36,
                                              child: Text(
                                                stageLabels[stage] ?? stage,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: isCompleted
                                                      ? Colors.green.shade700
                                                      : isCurrent
                                                      ? const Color(0xFF00A699)
                                                      : Colors.black54,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
