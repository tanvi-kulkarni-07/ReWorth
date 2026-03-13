import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/recycler_company.dart';
import '../models/nearby_company.dart';

/// Simple utility for loading a list of recycler companies from a bundled
/// JSON asset.  The dataset is expected to be an array of company objects in
/// the same format used throughout the app.
class CompanyDataService {
  /// Loads and parses the JSON file located at [assetPath].  By default the
  /// path is `assets/companies.json` but callers may override it if they have
  /// a different dataset (for example tests).
  static Future<List<RecyclerCompany>> loadFromAsset({
    String assetPath = 'assets/companies.json',
  }) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final decoded = json.decode(jsonStr);
    if (decoded is List<dynamic>) {
      return RecyclerCompany.fromJsonList(decoded);
    }
    throw FormatException('Unexpected JSON format: expected a list');
  }

  /// Convenience helper used by the logistics screen fallback.  It loads the
  /// same asset as [loadFromAsset], converts each company into a
  /// [NearbyCompany] and sorts the result by distance from [center].
  /// Companies without location data are silently dropped.
  static Future<List<NearbyCompany>> loadNearbyFromAsset({
    required LatLng center,
    String assetPath = 'assets/companies.json',
  }) async {
    try {
      final list = await loadFromAsset(assetPath: assetPath);
      final companies = list
          .where((c) => c.location != null)
          .map((c) {
            final loc = c.location!;
            final distance = Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              loc.latitude,
              loc.longitude,
            );
            return NearbyCompany(
              id: c.id,
              name: c.name,
              category: c.category,
              address: c.address,
              city: c.city,
              latitude: loc.latitude,
              longitude: loc.longitude,
              distanceMeters: distance,
              wasteTypes: c.wasteTypes,
              website: c.website,
              phone: c.phone,
            );
          })
          .toList(growable: false);

      companies.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return companies;
    } catch (_) {
      return const [];
    }
  }
}
