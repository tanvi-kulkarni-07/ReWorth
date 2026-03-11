import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationSearchResult {
  const LocationSearchResult({
    required this.position,
    required this.displayName,
    required this.outlines,
  });

  final LatLng position;
  final String displayName;
  final List<List<LatLng>> outlines;
}

class LocationSearchService {
  static const String _endpoint = 'https://nominatim.openstreetmap.org/search';
  static const String _lookupEndpoint =
      'https://nominatim.openstreetmap.org/lookup';
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'reworth/1.0 (smart-logistics-location-search)',
  };

  static Future<LocationSearchResult?> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return null;
    }

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': trimmedQuery,
        'format': 'jsonv2',
        'limit': '1',
        'polygon_geojson': '1',
      },
    );

    late final http.Response response;

    try {
      response = await http
          .get(uri, headers: _headers)
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception('Location search timed out');
    }

    if (response.statusCode != 200) {
      throw Exception('Location search failed (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    if (payload.isEmpty) {
      return null;
    }

    final first = payload.first as Map<String, dynamic>;
    final latitude = double.tryParse(first['lat']?.toString() ?? '');
    final longitude = double.tryParse(first['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) {
      return null;
    }

    var outlines = _parseOutlines(first['geojson']);
    if (outlines.isEmpty) {
      outlines = await _fetchLookupOutlines(first);
    }

    return LocationSearchResult(
      position: LatLng(latitude, longitude),
      displayName: first['display_name']?.toString() ?? trimmedQuery,
      outlines: outlines,
    );
  }

  static Future<List<List<LatLng>>> _fetchLookupOutlines(
    Map<String, dynamic> searchResult,
  ) async {
    final osmType = searchResult['osm_type']?.toString();
    final osmId = searchResult['osm_id']?.toString();
    if (osmType == null || osmId == null || osmType.isEmpty || osmId.isEmpty) {
      return const [];
    }

    final prefix = _lookupPrefix(osmType);
    if (prefix == null) {
      return const [];
    }

    final uri = Uri.parse(_lookupEndpoint).replace(
      queryParameters: {
        'format': 'jsonv2',
        'polygon_geojson': '1',
        'osm_ids': '$prefix$osmId',
      },
    );

    late final http.Response response;

    try {
      response = await http
          .get(uri, headers: _headers)
          .timeout(_requestTimeout);
    } on TimeoutException {
      return const [];
    }

    if (response.statusCode != 200) {
      return const [];
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    if (payload.isEmpty) {
      return const [];
    }

    final first = payload.first;
    if (first is! Map<String, dynamic>) {
      return const [];
    }

    return _parseOutlines(first['geojson']);
  }

  static String? _lookupPrefix(String osmType) {
    switch (osmType) {
      case 'node':
        return 'N';
      case 'way':
        return 'W';
      case 'relation':
        return 'R';
      default:
        return null;
    }
  }

  static List<List<LatLng>> _parseOutlines(dynamic geoJson) {
    if (geoJson is! Map) {
      return const [];
    }

    final type = geoJson['type']?.toString();
    final coordinates = geoJson['coordinates'];
    if (type == null || coordinates == null) {
      return const [];
    }

    switch (type) {
      case 'Polygon':
        return _parsePolygonCoordinates(coordinates);
      case 'MultiPolygon':
        return _parseMultiPolygonCoordinates(coordinates);
      case 'LineString':
        final line = _parseLineString(coordinates);
        return line.isEmpty ? const [] : [line];
      case 'MultiLineString':
        return _parseMultiLineStringCoordinates(coordinates);
      default:
        return const [];
    }
  }

  static List<List<LatLng>> _parsePolygonCoordinates(dynamic coordinates) {
    if (coordinates is! List) {
      return const [];
    }

    return coordinates
        .whereType<List>()
        .map(_parseLineString)
        .where((line) => line.length >= 2)
        .toList(growable: false);
  }

  static List<List<LatLng>> _parseMultiPolygonCoordinates(dynamic coordinates) {
    if (coordinates is! List) {
      return const [];
    }

    return coordinates
        .whereType<List>()
        .expand(_parsePolygonCoordinates)
        .toList(growable: false);
  }

  static List<List<LatLng>> _parseMultiLineStringCoordinates(
    dynamic coordinates,
  ) {
    if (coordinates is! List) {
      return const [];
    }

    return coordinates
        .whereType<List>()
        .map(_parseLineString)
        .where((line) => line.length >= 2)
        .toList(growable: false);
  }

  static List<LatLng> _parseLineString(dynamic coordinates) {
    if (coordinates is! List) {
      return const [];
    }

    final points = <LatLng>[];
    for (final coordinate in coordinates) {
      if (coordinate is List && coordinate.length >= 2) {
        final longitude = (coordinate[0] as num?)?.toDouble();
        final latitude = (coordinate[1] as num?)?.toDouble();
        if (latitude != null && longitude != null) {
          points.add(LatLng(latitude, longitude));
        }
      }
    }

    return points;
  }
}
