import 'package:flutter/material.dart';
import '../../models/recycler_company.dart';
import '../../services/company_data_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Marketplace showing recycler companies loaded from JSON asset. Users can
/// filter by waste type, search by name/city/type, and optionally restrict to
/// verified companies.  Tapping a company brings up the call/website sheet.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
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
          .where((c) => c.wasteTypes
              .map((w) => w.toLowerCase())
              .any((w) => w.contains(cat)))
          .toList();
    }
    if (_verifiedOnly) {
      list = list.where((c) => c.isVerified).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q) ||
            c.wasteTypes
                .map((w) => w.toLowerCase())
                .any((w) => w.contains(q));
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      final uri = 'tel:${company.phone.replaceAll(RegExp(r"\s+"), "")}';
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
                              mode: LaunchMode.externalApplication);
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
                  const Text('Filters',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search companies...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) {
                  _searchQuery = v;
                  _applyFilters();
                },
              )
            : const Text('Marketplace'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () {
              if (_showSearchBar) {
                _showSearchBar = false;
                _searchController.clear();
                _searchQuery = '';
                _applyFilters();
              } else {
                setState(() {
                  _showSearchBar = true;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // waste type chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _wasteTypes.map((type) {
                  final isSelected = type == _selectedWaste;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (sel) {
                        if (sel && _selectedWaste != type) {
                          _selectedWaste = type;
                          _applyFilters();
                        }
                      },
                      selectedColor: const Color(0xFF00A699),
                      backgroundColor: Colors.grey[200],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCompanies.isEmpty
                    ? const Center(child: Text('No companies found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredCompanies.length,
                        itemBuilder: (context, idx) {
                          final c = _filteredCompanies[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(c.name),
                              subtitle: Text('${c.category}\n${c.city}\n${c.phone}'),
                              isThreeLine: true,
                              trailing: Text(c.wasteTypes.join(', ')),
                              onTap: () => _showCompanyDetails(c),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
