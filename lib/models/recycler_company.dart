import 'package:latlong2/latlong.dart';

/// Simple value object representing a recycling / scrap company.
///
/// The structure mirrors the JSON documents stored in Firestore so it's
/// straightforward to convert between the two representations. At the
/// moment all fields are required because the sample data used by the app
/// always includes them, but in a real world application some of them could
/// be nullable.
class RecyclerCompany {
  const RecyclerCompany({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.wasteTypes,
    required this.phone,
    required this.website,
    required this.isActive,
    required this.isVerified,
    this.location,
  });

  final String id;
  final String name;
  final String category;
  final String address;
  final String city;
  final List<String> wasteTypes;
  final String phone;
  final String website;
  final bool isActive;
  final bool isVerified;

  /// Optional geographic location - not used by the filtering UI but
  /// included for completeness.
  final LatLng? location;

  /// Creates an instance from a map that was parsed from JSON / Firestore.
  factory RecyclerCompany.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    final lat = (loc?['latitude'] as num?)?.toDouble();
    final lng = (loc?['longitude'] as num?)?.toDouble();
    final generatedId = (json['id'] as String?) ??
        '${(json['name'] as String? ?? '').toLowerCase().replaceAll(' ', '_')}_${lat ?? 0}_${lng ?? 0}';

    return RecyclerCompany(
      id: generatedId,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      wasteTypes: (json['wasteTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? true,
      location: (lat != null && lng != null)
          ? LatLng(lat, lng)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'address': address,
        'city': city,
        'wasteTypes': wasteTypes,
        'phone': phone,
        'website': website,
        'isActive': isActive,
        'isVerified': isVerified,
        if (location != null)
          'location': {'latitude': location!.latitude, 'longitude': location!.longitude},
      };

  /// Utility to convert a decoded JSON list into model instances.
  static List<RecyclerCompany> fromJsonList(List<dynamic> list) {
    return list
        .map((e) => RecyclerCompany.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
