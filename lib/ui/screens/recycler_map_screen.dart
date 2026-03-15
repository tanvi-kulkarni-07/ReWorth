import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/recycler_company.dart';
import '../../services/company_data_service.dart';

/// Simple screen which reads all companies from the bundled JSON asset and
/// shows them as markers on a Google map.  Tapping a marker displays a
/// bottom sheet with the details (and a button to open the website).
class RecyclerMapScreen extends StatefulWidget {
  const RecyclerMapScreen({super.key});

  @override
  State<RecyclerMapScreen> createState() => _RecyclerMapScreenState();
}

class _RecyclerMapScreenState extends State<RecyclerMapScreen> {
  List<RecyclerCompany> _companies = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final list = await CompanyDataService.loadFromAsset();
      setState(() {
        _companies = list;
      });
    } catch (e) {
      debugPrint('Failed to load companies: $e');
    }
  }

  Set<Marker> get _markers {
    return _companies.where((c) => c.location != null).map((c) {
      final lat = c.location!.latitude;
      final lng = c.location!.longitude;
      return Marker(
        markerId: MarkerId(c.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: c.name,
          snippet: c.category,
          onTap: () => _showDetails(c),
        ),
        onTap: () => _showDetails(c),
      );
    }).toSet();
  }

  void _showDetails(RecyclerCompany company) {
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
              Text('Category: ${company.category}'),
              Text('City: ${company.city}'),
              Text('Waste types: ${company.wasteTypes.join(', ')}'),
              Text('Phone: ${company.phone}'),
              if (company.website.isNotEmpty)
                Text('Website: ${company.website}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = 'tel:${company.phone}';
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
                        if (await canLaunchUrlString(company.website)) {
                          await launchUrlString(
                            company.website,
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

  @override
  Widget build(BuildContext context) {
    final initialPos = const CameraPosition(
      target: LatLng(18.5204, 73.8567),
      zoom: 10,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycler Companies Map'),
        backgroundColor: const Color(0xFF00A699),
      ),
      body: GoogleMap(
        initialCameraPosition: initialPos,
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
