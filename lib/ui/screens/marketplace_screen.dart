import 'package:flutter/material.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Organic',
    'Plastic',
    'Metal',
    'Paper',
    'E-Waste',
  ];

  // Filter states
  bool _verifiedOnly = false;
  RangeValues _priceRange = const RangeValues(0, 100);
  String _sortBy = 'Distance';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: const Color(0xFF00A699),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Filter Summary Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_verifiedOnly)
                  Chip(
                    label: const Text('Verified Only'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _verifiedOnly = false;
                      });
                    },
                    backgroundColor: const Color(0xFF00A699).withOpacity(0.1),
                  ),
                const Spacer(),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, size: 20),
                  items:
                      [
                        'Distance',
                        'Price: Low to High',
                        'Price: High to Low',
                        'Rating',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _sortBy = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _getSampleItems().length,
              itemBuilder: (context, index) {
                final item = _getSampleItems()[index];
                return _buildWasteCard(
                  item['type']!,
                  item['quantity']!,
                  item['price']!,
                  item['rating']!,
                  item['distance']!,
                  item['seller']!,
                  item['verified'] == 'true',
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create_listing');
        },
        backgroundColor: const Color(0xFF00A699),
        icon: const Icon(Icons.add),
        label: const Text('Sell Waste'),
      ),
    );
  }

  List<Map<String, String>> _getSampleItems() {
    return [
      {
        'type': 'Banana Peels',
        'quantity': '50 kg',
        'price': '₹12',
        'rating': '4.5',
        'distance': '2.3 km',
        'seller': 'Green Farms',
        'verified': 'true',
      },
      {
        'type': 'Plastic Bottles',
        'quantity': '120 kg',
        'price': '₹25',
        'rating': '4.8',
        'distance': '1.5 km',
        'seller': 'EcoCollect',
        'verified': 'true',
      },
      {
        'type': 'Metal Scraps',
        'quantity': '200 kg',
        'price': '₹45',
        'rating': '4.2',
        'distance': '5.1 km',
        'seller': 'Steel Recyclers',
        'verified': 'false',
      },
      {
        'type': 'Cardboard Boxes',
        'quantity': '80 kg',
        'price': '₹8',
        'rating': '4.6',
        'distance': '3.7 km',
        'seller': 'Paper Hub',
        'verified': 'true',
      },
      {
        'type': 'Electronic Waste',
        'quantity': '35 kg',
        'price': '₹150',
        'rating': '4.9',
        'distance': '4.2 km',
        'seller': 'Tech Recycle',
        'verified': 'true',
      },
      {
        'type': 'Glass Bottles',
        'quantity': '95 kg',
        'price': '₹15',
        'rating': '4.3',
        'distance': '2.8 km',
        'seller': 'Glass Masters',
        'verified': 'false',
      },
    ];
  }

  Widget _buildWasteCard(
    String wasteType,
    String quantity,
    String price,
    String rating,
    String distance,
    String seller,
    bool verified,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to item details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A699).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForWasteType(wasteType),
                  size: 40,
                  color: const Color(0xFF00A699),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wasteType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (verified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quantity: $quantity',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$price/kg',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A699),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 2),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.store, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            seller,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForWasteType(String wasteType) {
    if (wasteType.contains('Banana') || wasteType.contains('Organic')) {
      return Icons.eco;
    } else if (wasteType.contains('Plastic')) {
      return Icons.recycling;
    } else if (wasteType.contains('Metal')) {
      return Icons.hardware;
    } else if (wasteType.contains('Paper') || wasteType.contains('Cardboard')) {
      return Icons.description;
    } else if (wasteType.contains('Electronic') || wasteType.contains('E-')) {
      return Icons.devices;
    } else if (wasteType.contains('Glass')) {
      return Icons.coffee;
    }
    return Icons.category;
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Waste'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Enter waste type...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement search
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A699),
              ),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _verifiedOnly = false;
                            _priceRange = const RangeValues(0, 100);
                          });
                          setState(() {
                            _verifiedOnly = false;
                            _priceRange = const RangeValues(0, 100);
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Verified Sellers Only
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verified Sellers Only',
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: _verifiedOnly,
                        onChanged: (value) {
                          setModalState(() {
                            _verifiedOnly = value;
                          });
                          setState(() {
                            _verifiedOnly = value;
                          });
                        },
                        activeColor: const Color(0xFF00A699),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Price Range
                  const Text(
                    'Price Range (₹/kg)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 200,
                    divisions: 20,
                    activeColor: const Color(0xFF00A699),
                    labels: RangeLabels(
                      '₹${_priceRange.start.round()}',
                      '₹${_priceRange.end.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setModalState(() {
                        _priceRange = values;
                      });
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${_priceRange.start.round()}'),
                      Text('₹${_priceRange.end.round()}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Location Filter
                  const Text(
                    'Distance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('< 2 km'),
                        onSelected: (selected) {},
                      ),
                      FilterChip(
                        label: const Text('< 5 km'),
                        onSelected: (selected) {},
                      ),
                      FilterChip(
                        label: const Text('< 10 km'),
                        onSelected: (selected) {},
                      ),
                      FilterChip(
                        label: const Text('Any'),
                        onSelected: (selected) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A699),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
