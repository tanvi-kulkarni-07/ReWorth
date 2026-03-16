import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_providers.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  static const Map<String, LatLng> _sellerLocationCoordinates = {
    'Pune': LatLng(18.5204, 73.8567),
    'Mumbai': LatLng(19.0760, 72.8777),
    'Nashik': LatLng(19.9975, 73.7898),
    'Thane': LatLng(19.2183, 72.9781),
    'Aurangabad': LatLng(19.8762, 75.3433),
    'Nagpur': LatLng(21.1458, 79.0882),
    'Kolhapur': LatLng(16.7050, 74.2433),
    'Delhi': LatLng(28.7041, 77.1025),
    'Bengaluru': LatLng(12.9716, 77.5946),
    'Chennai': LatLng(13.0827, 80.2707),
    'Noida': LatLng(28.5355, 77.3910),
    'Hyderabad': LatLng(17.3850, 78.4867),
  };

  LatLng _sellerLatLng(String location) {
    return _sellerLocationCoordinates[location] ?? const LatLng(20.5937, 78.9629);
  }

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
    final myListings = ref
        .watch(listingsProvider)
        .where((listing) => listing.sellerName == seller)
        .toList();

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
        child: myListings.isEmpty
            ? const Center(
                child: Text(
                  'No listings yet',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myListings.length,
                itemBuilder: (context, index) {
                  final listing = myListings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.wasteType,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Weight: ${listing.weightKg.toStringAsFixed(1)} kg',
                          ),
                          Text(
                            'Price/kg: ₹${listing.pricePerKg.toStringAsFixed(0)}',
                          ),
                          Text('Company: ${listing.companyName}'),
                          Text('Location: ${listing.sellerLocation}'),
                          const SizedBox(height: 8),
                          _buildStatusWidget(context, ref, listing),
                          if (listing.status == 'available') _buildCompanyButtons(context, ref, listing),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCompanyButtons(BuildContext context, WidgetRef ref, WasteListing listing) {
    final wasteTypeLower = listing.wasteType.toLowerCase().replaceAll(' waste', '');
    final matchingCompanies = companies.where((company) =>
        company.wasteTypes.contains(wasteTypeLower) ||
        company.wasteTypes.contains('mixed') ||
        company.wasteTypes.contains('municipal')
    ).toList();

    if (matchingCompanies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'No matching companies found for this waste type',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Send Request to Companies:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: matchingCompanies.map((company) {
            return ElevatedButton(
              onPressed: () {
                _sendRequestToCompany(context, ref, listing, company);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text('Request ${company.name}'),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _sendRequestToCompany(
    BuildContext context,
    WidgetRef ref,
    WasteListing listing,
    Company company,
  ) async {
    final sellerId = ref.read(userIdProvider) ?? '';
    final sellerName = ref.read(userNameProvider) ?? '';

    final quantityController = TextEditingController(text: listing.weightKg.toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter quantity (kg)'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Quantity in kg'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final quantity = double.tryParse(quantityController.text.trim()) ?? listing.weightKg;
    final sellerLatLng = _sellerLatLng(listing.sellerLocation);
    final companyLat = (company.location['latitude'] as double?) ?? 0.0;
    final companyLng = (company.location['longitude'] as double?) ?? 0.0;

    final docRef = await FirebaseFirestore.instance.collection('pickup_requests').add({
      'sellerId': sellerId,
      'sellerName': sellerName,
      'wasteType': listing.wasteType,
      'weight': quantity,
      'companyName': company.name,
      'companyLat': companyLat,
      'companyLng': companyLng,
      'sellerLat': sellerLatLng.latitude,
      'sellerLng': sellerLatLng.longitude,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final listingsNotifier = ref.read(listingsProvider.notifier);
    listingsNotifier.updateListingStatus(
      listing.sellerName,
      listing.wasteType,
      'company_selected',
      buyerName: company.name,
      pickupRequestId: docRef.id,
      sentAt: DateTime.now(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You have successfully selected ${company.name}.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context, WidgetRef ref, WasteListing listing) {
    switch (listing.status) {
      case 'available':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue),
          ),
          child: const Text(
            'Available for buyer requests',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        );
      case 'company_selected':
        final company = companies.firstWhere(
          (c) => c.name == listing.buyerName,
          orElse: () => Company(
            name: '',
            category: '',
            wasteTypes: [],
            phone: '',
            website: '',
            address: '',
            city: '',
            location: {},
            isActive: false,
            isVerified: false,
            ownerUid: '',
            updatedAt: '',
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                'Company selected: ${listing.buyerName ?? 'Unknown'}',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            if (company.name.isNotEmpty)
              Text(
                'Contact: ${company.phone}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (company.website.isNotEmpty)
              Text(
                'Website: ${company.website}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                if (listing.pickupRequestId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No pickup request found to confirm.'),
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('pickup_requests')
                    .doc(listing.pickupRequestId)
                    .update({'status': 'accepted'});

                ref.read(listingsProvider.notifier).updateListingStatus(
                      listing.sellerName,
                      listing.wasteType,
                      'pickup_started',
                      buyerName: listing.buyerName,
                      acceptedAt: DateTime.now(),
                    );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have successfully confirmed the company.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Confirm Pickup'),
            ),
          ],
        );
      case 'pickup_started':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                'Pickup started — track in Pickup section',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pickup_requests');
              },
              child: const Text('Go to Pickup Section'),
            ),
          ],
        );
      case 'request_sent':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                'Request sent — waiting for buyer confirmation',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sent to: ${listing.buyerName ?? 'Buyer'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (listing.requestSentAt != null)
              Text(
                'Sent on: ${_formatDateTime(listing.requestSentAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        );
      case 'request_accepted':
        final company = companies.firstWhere(
          (c) => c.name == listing.buyerName,
          orElse: () => Company(
            name: '',
            category: '',
            wasteTypes: [],
            phone: '',
            website: '',
            address: '',
            city: '',
            location: {},
            isActive: false,
            isVerified: false,
            ownerUid: '',
            updatedAt: '',
          ),
        );
        if (company.name.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  '✓ Your request has been accepted by ${company.name}!',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Contact: ${company.phone}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (company.website.isNotEmpty)
                Text(
                  'Website: ${company.website}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (listing.requestAcceptedAt != null)
                Text(
                  'Accepted on: ${_formatDateTime(listing.requestAcceptedAt!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  '✓ Your request has been accepted by the buyer!',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Accepted by: ${listing.buyerName ?? 'Buyer'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (listing.requestAcceptedAt != null)
                Text(
                  'Accepted on: ${_formatDateTime(listing.requestAcceptedAt!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          );
        }
      default:
        return Text('Status: ${listing.status}');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
