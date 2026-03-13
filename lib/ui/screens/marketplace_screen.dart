import 'package:flutter/material.dart';
import '../../models/recycler_company.dart';
import '../../services/company_data_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/listing_providers.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dashboard_screen.dart';

/// Marketplace showing recycler companies loaded from JSON asset. Users can
/// filter by waste type, search by name/city/type, and optionally restrict to
/// verified companies.  Tapping a company brings up the call/website sheet.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late String? _role;
  List<WasteListing> _listings = [];

  bool _isLoading = true;
  List<RecyclerCompany> _allCompanies = [];
  List<RecyclerCompany> _filteredCompanies = [];

  List<String> _wasteTypes = ['All'];
  String _selectedWaste = 'All';

  bool _verifiedOnly = false;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    // nothing changes for recycler company list (seller view)
    try {
      final list = await CompanyDataService.loadFromAsset();
      setState(() {
        _allCompanies = list;
        _wasteTypes = ['All', ..._extractWasteTypes(list)];
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('Unable to load companies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _extractWasteTypes(List<RecyclerCompany> companies) {
    final types = <String>{};
    for (final c in companies) {
      for (final w in c.wasteTypes) {
        types.add(w.toLowerCase());
      }
    }
    final sorted = types.toList()..sort();
    return sorted.map((t) => t[0].toUpperCase() + t.substring(1)).toList();
  }

  void _applyFilters() {
    var list = _allCompanies;
    if (_selectedWaste != 'All') {
      final cat = _selectedWaste.toLowerCase();
      list = list
          .where(
            (c) => c.wasteTypes
                .map((w) => w.toLowerCase())
                .any((w) => w.contains(cat)),
          )
          .toList();
    }
    // always sort alphabetically by name for consistent order
    list.sort((a, b) => a.name.compareTo(b.name));
    if (_verifiedOnly) {
      list = list.where((c) => c.isVerified).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q) ||
            c.wasteTypes.map((w) => w.toLowerCase()).any((w) => w.contains(q));
      }).toList();
    }
    setState(() {
      _filteredCompanies = list;
    });
  }

  void _showCompanyDetails(RecyclerCompany company) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Address: ${company.address}'),
              Text('Waste types: ${company.wasteTypes.join(', ')}'),
              Text('Phone: ${company.phone}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri =
                          'tel:${company.phone.replaceAll(RegExp(r"\s+"), "")}';
                      if (await canLaunchUrlString(uri)) {
                        await launchUrlString(uri);
                      }
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Company'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A699),
                    ),
                  ),
                  if (company.website.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () async {
                        var url = company.website;
                        if (!url.startsWith('http')) {
                          url = 'https://$url';
                        }
                        if (await canLaunchUrlString(url)) {
                          await launchUrlString(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.language),
                      label: const Text('Visit Website'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A699),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      _verifiedOnly = false;
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Verified only'),
                  Switch(
                    value: _verifiedOnly,
                    onChanged: (v) {
                      setState(() {
                        _verifiedOnly = v;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    activeColor: const Color(0xFF00A699),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarketplaceCard(RecyclerCompany c) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: () => _showCompanyDetails(c),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (c.isVerified)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${c.category} • ${c.city}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: c.wasteTypes
                    .map(
                      (w) => Chip(
                        label: Text(w),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
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

      // buyer marketplace: show waste listings from provider
      final listings = ref.watch(listingsProvider);
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Marketplace'),
          backgroundColor: const Color(0xFF00A699),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: listings.isEmpty
            ? const Center(
                child: Text('No waste listings available',
                    style: TextStyle(fontSize: 18)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final item = listings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.wasteType,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Weight: ${item.weightKg} kg'),
                          Text('Price/kg: ₹${item.pricePerKg}'),
                          Text('Total: ₹${item.totalValue.toStringAsFixed(0)}'),
                          Text('Seller: ${item.sellerName}'),
                          Text('Location: ${item.sellerLocation}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              // create order
                              ref.read(ordersProvider.notifier).addOrder(
                                    Order(
                                      wasteType: item.wasteType,
                                      weight: item.weightKg,
                                      sellerName: item.sellerName,
                                      companyName: item.companyName,
                                    ),
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Order placed')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A699),
                            ),
                            child: const Text('Request Pickup'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }
}
