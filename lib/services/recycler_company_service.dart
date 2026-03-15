import '../models/recycler_company.dart';
import 'package:latlong2/latlong.dart';

/// Lightweight helper class that holds a hardcoded list of companies and
/// provides an easy way to filter them by detected waste type.
///
/// In a production app this would probably talk to Firestore (or your
/// backend) but for the purposes of the exercise we keep the data local.
class RecyclerCompanyService {
  /// Example list built from the README and the seed data that already exists
  /// in the codebase. You can replace this with JSON loaded from assets or
  /// from your network layer when the real list is available.
  static final List<RecyclerCompany> demoCompanies = [
    RecyclerCompany(
      id: 'green_scrap',
      name: 'Green Scrap Traders',
      category: 'Scrap buyer',
      address: '12 Market Road',
      city: 'Bengaluru',
      wasteTypes: const ['metal', 'plastic', 'paper'],
      phone: '+91 9876543210',
      website: 'https://greenscrap.example',
      isActive: true,
      isVerified: true,
      location: const LatLng(12.9716, 77.5946),
    ),
    RecyclerCompany(
      id: 'eco_recycle',
      name: 'EcoRecycle Hub',
      category: 'Recycling center',
      address: 'Plot 18, MIDC Industrial Area, Andheri East',
      city: 'Mumbai',
      wasteTypes: const ['plastic', 'paper', 'glass', 'cardboard'],
      phone: '+91 9876541201',
      website: 'https://ecogreenrecycling.in',
      isActive: true,
      isVerified: true,
      location: const LatLng(19.1176, 72.8647),
    ),
    // add more records here as needed
  ];

  /// Filters a list of companies by the detected waste label coming from the
  /// AI model.  The model often returns detailed labels like
  /// "medium_plastic" or "plastic_bottle"; the simple algorithm below
  /// extracts the base word (last segment after an underscore) and checks for
  /// membership in each company's wasteTypes list.
  static List<RecyclerCompany> filterByDetectedWaste(
    String detectedLabel, {
    List<RecyclerCompany>? source,
  }) {
    final normalized = detectedLabel.toLowerCase();
    final companies = source ?? demoCompanies;

    // Map some labels to their corresponding waste types
    final labelToWasteType = {
      'e-waste': 'electronics',
      'wet waste': 'organic',
      'paper waste': 'paper',
      'crop waste': 'organic',
      'farm waste': 'organic',
      'flower waste': 'organic',
      // Add more mappings as needed
    };

    final effectiveLabel = labelToWasteType[normalized] ?? normalized;

    // a simple substring check means labels such as "medium_plastic",
    // "plastic_bottle" or "plastic" will all match a company whose
    // wasteTypes list contains "plastic".  This keeps the matcher very
    // forgiving without having to maintain a separate mapping table.
    return companies.where((c) {
      return c.wasteTypes
          .map((w) => w.toLowerCase())
          .any((w) => effectiveLabel.contains(w) || w.contains(effectiveLabel));
    }).toList();
  }
}
