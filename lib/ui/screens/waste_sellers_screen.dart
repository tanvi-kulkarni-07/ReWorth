import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../providers/listing_providers.dart';
import '../../services/company_data_service.dart';
import '../../models/recycler_company.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class WasteSellersScreen extends ConsumerStatefulWidget {
  final String wasteType;

  const WasteSellersScreen({super.key, required this.wasteType});

  @override
  ConsumerState<WasteSellersScreen> createState() => _WasteSellersScreenState();
}

class _WasteSellersScreenState extends ConsumerState<WasteSellersScreen> {
  List<RecyclerCompany> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await CompanyDataService.loadFromAsset();
      if (mounted) {
        setState(() {
          _companies = companies;
        });
      }
    } catch (e) {
      debugPrint('Failed to load companies: $e');
    }
  }

  RecyclerCompany? _getCompanyByName(String name) {
    return _companies.cast<RecyclerCompany?>().firstWhere(
          (c) => c!.name == name,
          orElse: () => null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    if (role != null && role != 'buyer') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    final listings = ref.watch(listingsProvider);
    final filteredListings = listings.where((l) => l.wasteType == widget.wasteType).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.wasteType} Sellers'),
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
      body: filteredListings.isEmpty
          ? const Center(
              child: Text('No sellers available for this waste type.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredListings.length,
              itemBuilder: (context, index) {
                final listing = filteredListings[index];
                final company = _getCompanyByName(listing.companyName);

                return GestureDetector(
                  onTap: listing.status == 'available' ? () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Selection'),
                        content: Text(
                          'Are you sure you want to select ${listing.sellerName} for ${listing.weightKg}kg of ${listing.wasteType}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final buyerName = ref.watch(userNameProvider) ?? 'Buyer';
                      final buyerId = ref.read(userIdProvider) ?? 'anonymous';
                      ref.read(listingsProvider.notifier).updateListingStatus(
                            listing.sellerName,
                            listing.wasteType,
                            'request_sent',
                            buyerName: buyerName,
                            sentAt: DateTime.now(),
                          );

                      ref.read(ordersProvider.notifier).addOrder(
                            Order(
                              wasteType: listing.wasteType,
                              weight: listing.weightKg,
                              sellerName: listing.sellerName,
                              companyName: listing.companyName,
                              sellerLocation: listing.sellerLocation,
                              buyerId: buyerId,
                              contactPhone: listing.contactPhone,
                            ),
                          );

                      if (mounted) {
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          const SnackBar(
                            content: Text('Selection confirmed! Check your orders to accept the request.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } : null,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          listing.sellerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Waste Type: ${listing.wasteType}'),
                        Text('Quantity: ${(listing.weightKg / 1000).toStringAsFixed(1)} tons'),
                        Text('Price: ₹${listing.pricePerKg.toStringAsFixed(0)}/kg'),
                        Text('Location: ${listing.sellerLocation}'),
                        const SizedBox(height: 8),
                        Text('Contact: ${listing.contactPhone}'),
                        if (company != null) ...[
                          const SizedBox(height: 8),
                          Text('Company: ${company.name}'),
                          Text('Website: ${company.website}'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final sanitizedNumber = listing.contactPhone.replaceAll(RegExp(r"\s+"), "");
                                  final uri = 'tel:$sanitizedNumber';
                                  if (await canLaunchUrlString(uri)) {
                                    await launchUrlString(uri);
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                        const SnackBar(content: Text('Unable to open dialer.')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('Call Seller'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A699),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  var url = company.website;
                                  if (!url.startsWith('http')) {
                                    url = 'https://$url';
                                  }
                                  if (await canLaunchUrlString(url)) {
                                    await launchUrlString(url, mode: LaunchMode.externalApplication);
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                        const SnackBar(content: Text('Could not open website.')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.language),
                                label: const Text('Company Website'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A699),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),);
              },
            ),
    );
  }
}