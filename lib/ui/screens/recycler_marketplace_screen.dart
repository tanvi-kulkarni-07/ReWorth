import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/recycler_company.dart';

/// Screen showing a set of recycling companies either as a list or on a map.
///
/// The entire list is provided by the caller (typically filtered by waste
/// type).  A segmented control at the top toggles between the two views.
class RecyclerMarketplaceScreen extends StatefulWidget {
  const RecyclerMarketplaceScreen({
    Key? key,
    required this.companies,
    this.initialWasteLabel,
  }) : super(key: key);

  /// Companies that should be rendered in the UI.
  final List<RecyclerCompany> companies;

  /// Optional label that was used to filter the list; purely for display.
  final String? initialWasteLabel;

  @override
  State<RecyclerMarketplaceScreen> createState() =>
      _RecyclerMarketplaceScreenState();
}

class _RecyclerMarketplaceScreenState
    extends State<RecyclerMarketplaceScreen> {
  bool _showMap = false;
  GoogleMapController? _mapController;

  Set<Marker> get _markers {
    return widget.companies.map((c) {
      return Marker(
        markerId: MarkerId(c.id),
        position: LatLng(c.location?.latitude ?? 0, c.location?.longitude ?? 0),
        infoWindow: InfoWindow(
          title: c.name,
          snippet: c.category,
          onTap: () => _showCompanyDetails(c),
        ),
        onTap: () => _showCompanyDetails(c),
      );
    }).toSet();
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
              if (company.website.isNotEmpty) Text('Website: ${company.website}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _callCompany(company.phone),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Company'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A699),
                    ),
                  ),
                  if (company.website.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _openWebsite(company.website),
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

  Future<void> _callCompany(String phone) async {
    final uri = 'tel:$phone';
    if (await canLaunchUrlString(uri)) {
      await launchUrlString(uri);
    }
  }

  Future<void> _openWebsite(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialWasteLabel != null
            ? 'Companies for ${widget.initialWasteLabel!}'
            : 'Recycler Marketplace'),
        backgroundColor: const Color(0xFF00A699),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
            tooltip: _showMap ? 'Show list' : 'Show map',
          ),
        ],
      ),
      body: _showMap ? _buildMapView() : _buildListView(),
    );
  }

  Widget _buildListView() {
    if (widget.companies.isEmpty) {
      return const Center(child: Text('No companies found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.companies.length,
      itemBuilder: (context, index) {
        final c = widget.companies[index];
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
    );
  }

  Widget _buildMapView() {
    if (widget.companies.isEmpty) {
      return const Center(child: Text('No companies to show on map.'));
    }

    final firstLocation = widget.companies.first.location;
    final initialPosition = CameraPosition(
      target: LatLng(firstLocation?.latitude ?? 0, firstLocation?.longitude ?? 0),
      zoom: 10,
    );

    return GoogleMap(
      initialCameraPosition: initialPosition,
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }
}
