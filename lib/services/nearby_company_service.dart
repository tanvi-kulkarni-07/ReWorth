import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/nearby_company.dart';

class NearbyCompanyService {
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Map<String, String> _headers = {
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    'Accept': 'application/json',
    'User-Agent': 'reworth/1.0 (nearby-company-search)',
  };

  static Future<List<NearbyCompany>> fetchNearbyCompanies({
    required LatLng center,
    int radiusMeters = 15000,
  }) async {
    late final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: _headers,
            body: {
              'data': _buildQuery(
                latitude: center.latitude,
                longitude: center.longitude,
                radiusMeters: radiusMeters,
              ),
            },
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception('Nearby buyers lookup timed out');
    }

    if (response.statusCode != 200) {
      throw Exception('Nearby buyers lookup failed (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (payload['elements'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    final seen = <String>{};
    final companies = <NearbyCompany>[];

    for (final element in elements) {
      try {
        final company = NearbyCompany.fromOverpassElement(
          element: element,
          userLatitude: center.latitude,
          userLongitude: center.longitude,
        );
        if (seen.add(company.id)) {
          companies.add(company);
        }
      } on FormatException {
        continue;
      }
    }

    companies.sort((first, second) {
      return first.distanceMeters.compareTo(second.distanceMeters);
    });

    return companies.take(30).toList(growable: false);
  }

  static String _buildQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    return '''
[out:json][timeout:25];
(
  node["amenity"="recycling"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="recycling"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="recycling"](around:$radiusMeters,$latitude,$longitude);
  node["shop"="scrap"](around:$radiusMeters,$latitude,$longitude);
  way["shop"="scrap"](around:$radiusMeters,$latitude,$longitude);
  relation["shop"="scrap"](around:$radiusMeters,$latitude,$longitude);
  node["office"="waste_management"](around:$radiusMeters,$latitude,$longitude);
  way["office"="waste_management"](around:$radiusMeters,$latitude,$longitude);
  relation["office"="waste_management"](around:$radiusMeters,$latitude,$longitude);
  node["industrial"="scrap_yard"](around:$radiusMeters,$latitude,$longitude);
  way["industrial"="scrap_yard"](around:$radiusMeters,$latitude,$longitude);
  relation["industrial"="scrap_yard"](around:$radiusMeters,$latitude,$longitude);
);
out center tags;
''';
  }
}
