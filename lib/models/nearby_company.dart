import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class NearbyCompany {
  const NearbyCompany({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.wasteTypes,
    this.website,
    this.phone,
  });

  final String id;
  final String name;
  final String category;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final List<String> wasteTypes;
  final String? website;
  final String? phone;

  LatLng get latLng => LatLng(latitude, longitude);

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get locationLabel {
    if (address.isNotEmpty && city.isNotEmpty) {
      return '$address, $city';
    }
    if (address.isNotEmpty) {
      return address;
    }
    if (city.isNotEmpty) {
      return city;
    }

    return 'Nearby location';
  }

  String get wasteTypesLabel {
    if (wasteTypes.isEmpty) {
      return 'Mixed recyclable waste';
    }

    return wasteTypes.join(', ');
  }

  bool matchesSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final haystack = [
      name,
      category,
      address,
      city,
      ...wasteTypes,
    ].join(' ').toLowerCase();

    return haystack.contains(normalizedQuery);
  }

  factory NearbyCompany.fromOverpassElement({
    required Map<String, dynamic> element,
    required double userLatitude,
    required double userLongitude,
  }) {
    final tags = Map<String, dynamic>.from(
      (element['tags'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final center = Map<String, dynamic>.from(
      (element['center'] as Map?)?.cast<String, dynamic>() ?? const {},
    );

    final latitude =
        (element['lat'] as num?)?.toDouble() ??
        (center['lat'] as num?)?.toDouble();
    final longitude =
        (element['lon'] as num?)?.toDouble() ??
        (center['lon'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      throw const FormatException('Missing coordinates');
    }

    final name =
        _firstNonEmpty([tags['name'], tags['operator'], tags['brand']]) ??
        'Recycling facility';

    final city =
        _firstNonEmpty([
          tags['addr:city'],
          tags['addr:suburb'],
          tags['addr:district'],
          tags['addr:state'],
        ]) ??
        '';

    final address = _buildAddress(tags);
    final category = _buildCategory(tags);
    final wasteTypes = _buildWasteTypes(tags, category);
    final website = _normalizeUrl(
      _firstNonEmpty([tags['website'], tags['contact:website']]),
    );
    final phone = _firstNonEmpty([tags['phone'], tags['contact:phone']]);

    return NearbyCompany(
      id: '${name.toLowerCase()}_${latitude.toStringAsFixed(5)}_${longitude.toStringAsFixed(5)}',
      name: name,
      category: category,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        latitude,
        longitude,
      ),
      wasteTypes: wasteTypes,
      website: website,
      phone: phone,
    );
  }

  factory NearbyCompany.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required double userLatitude,
    required double userLongitude,
  }) {
    final coordinates = _parseCoordinates(data['location']);
    if (coordinates == null) {
      throw const FormatException('Missing coordinates');
    }

    final wasteTypes = _parseWasteTypes(data['wasteTypes']);
    final category = _firstNonEmpty([data['category']]) ?? 'Buyer / recycler';

    return NearbyCompany(
      id: id,
      name:
          _firstNonEmpty([data['name'], data['companyName']]) ??
          'Recycling facility',
      category: category,
      address: _firstNonEmpty([data['address'], data['streetAddress']]) ?? '',
      city:
          _firstNonEmpty([data['city'], data['district'], data['state']]) ?? '',
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      distanceMeters: Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        coordinates.latitude,
        coordinates.longitude,
      ),
      wasteTypes: wasteTypes.isEmpty
          ? _buildWasteTypes(const {}, category)
          : wasteTypes,
      website: _normalizeUrl(
        _firstNonEmpty([
          data['website'],
          data['contactWebsite'],
          data['companyWebsite'],
          data['url'],
          data['link'],
          data['web'],
        ]),
      ),
      phone: _firstNonEmpty([data['phone'], data['contactPhone']]),
    );
  }

  factory NearbyCompany.fromJson({
    required Map<String, dynamic> json,
    required double userLatitude,
    required double userLongitude,
  }) {
    final location = json['location'] as Map<String, dynamic>?;
    if (location == null) {
      throw const FormatException('Missing location data');
    }

    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      throw const FormatException('Missing coordinates in location');
    }

    final wasteTypes = _parseWasteTypes(json['wasteTypes']);
    final name = json['name'] as String? ?? 'Unknown Company';
    final category = json['category'] as String? ?? 'Buyer / recycler';
    final address = json['address'] as String? ?? '';
    final city = json['city'] as String? ?? '';
    final website = json['website'] as String?;
    final phone = json['phone'] as String?;

    return NearbyCompany(
      id: '${name.toLowerCase().replaceAll(' ', '_')}_${latitude.toStringAsFixed(5)}_${longitude.toStringAsFixed(5)}',
      name: name,
      category: category,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        latitude,
        longitude,
      ),
      wasteTypes: wasteTypes.isNotEmpty ? wasteTypes : ['mixed waste'],
      website: website,
      phone: phone,
    );
  }

  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = [
      _firstNonEmpty([tags['addr:housenumber']]),
      _firstNonEmpty([tags['addr:street']]),
      _firstNonEmpty([tags['addr:neighbourhood']]),
      _firstNonEmpty([tags['addr:suburb']]),
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return _firstNonEmpty([
          tags['description'],
          tags['addr:full'],
          tags['branch'],
        ]) ??
        '';
  }

  static String _buildCategory(Map<String, dynamic> tags) {
    final amenity = tags['amenity']?.toString();
    final shop = tags['shop']?.toString();
    final office = tags['office']?.toString();
    final industrial = tags['industrial']?.toString();
    final recyclingType = tags['recycling_type']?.toString();

    if (amenity == 'recycling') {
      if (recyclingType != null && recyclingType.isNotEmpty) {
        return 'Recycling center · $recyclingType';
      }
      return 'Recycling center';
    }
    if (shop == 'scrap') {
      return 'Scrap buyer';
    }
    if (office == 'waste_management') {
      return 'Waste management company';
    }
    if (industrial == 'scrap_yard') {
      return 'Scrap yard';
    }

    return 'Buyer / recycler';
  }

  static List<String> _buildWasteTypes(
    Map<String, dynamic> tags,
    String category,
  ) {
    const recyclingKeys = [
      'recycling:paper',
      'recycling:plastic',
      'recycling:glass',
      'recycling:metal',
      'recycling:electronics',
      'recycling:batteries',
      'recycling:clothes',
      'recycling:organic',
      'recycling:wood',
      'recycling:cardboard',
      'recycling:books',
      'recycling:cans',
    ];

    final wasteTypes = <String>[];
    for (final key in recyclingKeys) {
      final value = tags[key]?.toString().toLowerCase();
      if (value == 'yes' || value == 'true' || value == 'only') {
        wasteTypes.add(_humanizeWasteKey(key));
      }
    }

    if (wasteTypes.isNotEmpty) {
      return wasteTypes;
    }

    final normalizedCategory = category.toLowerCase();
    if (normalizedCategory.contains('scrap')) {
      return const ['metal', 'plastic', 'paper'];
    }
    if (normalizedCategory.contains('waste management')) {
      return const ['mixed waste', 'plastic', 'paper', 'organic'];
    }
    if (normalizedCategory.contains('recycling')) {
      return const ['plastic', 'paper', 'glass', 'metal'];
    }

    return const ['mixed recyclable waste'];
  }

  static String _humanizeWasteKey(String key) {
    final parts = key.split(':');
    if (parts.length < 2) {
      return key;
    }

    final raw = parts[1];
    if (raw == 'electronics') {
      return 'e-waste';
    }

    return raw;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static String? _normalizeUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return 'https://$value';
  }

  static List<String> _parseWasteTypes(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }

  static ({double latitude, double longitude})? _parseCoordinates(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return (latitude: value.latitude, longitude: value.longitude);
    }

    if (value is Map) {
      final latitude = (value['latitude'] ?? value['lat'] as num?)?.toDouble();
      final longitude =
          (value['longitude'] ?? value['lng'] ?? value['lon'] as num?)
              ?.toDouble();
      if (latitude != null && longitude != null) {
        return (latitude: latitude, longitude: longitude);
      }
    }

    return null;
  }
}
