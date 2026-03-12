import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/recycler_company.dart';

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
}
