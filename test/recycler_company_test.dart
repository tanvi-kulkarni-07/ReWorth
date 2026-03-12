import 'package:flutter_test/flutter_test.dart';
import 'package:reworth/models/recycler_company.dart';
import 'package:reworth/services/recycler_company_service.dart';

void main() {
  group('RecyclerCompanyService.filterByDetectedWaste', () {
    final companies = [
      RecyclerCompany(
        id: '1',
        name: 'Plastic Co',
        category: 'Recycling center',
        address: '123',
        city: 'City',
        wasteTypes: const ['plastic'],
        phone: '123',
        website: 'https://example.com',
        isActive: true,
        isVerified: true,
      ),
      RecyclerCompany(
        id: '2',
        name: 'Metal Co',
        category: 'Scrap buyer',
        address: '456',
        city: 'City',
        wasteTypes: const ['metal'],
        phone: '456',
        website: 'https://example.com',
        isActive: true,
        isVerified: true,
      ),
    ];

    test('matches when detected label contains waste type', () {
      final filtered =
          RecyclerCompanyService.filterByDetectedWaste('medium_plastic',
              source: companies);
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Plastic Co');
    });

    test('is case insensitive', () {
      final filtered =
          RecyclerCompanyService.filterByDetectedWaste('Plastic_Bottle',
              source: companies);
      expect(filtered.length, 1);
    });

    test('returns empty list when no match', () {
      final filtered =
          RecyclerCompanyService.filterByDetectedWaste('glass_item',
              source: companies);
      expect(filtered, isEmpty);
    });
  });
}
