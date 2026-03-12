import 'package:flutter_test/flutter_test.dart';
import 'package:reworth/services/company_data_service.dart';
import 'package:reworth/services/recycler_company_service.dart';
import 'package:reworth/models/recycler_company.dart';

void main() {
  // ensure asset bundle is available for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CompanyDataService loads companies from asset', () async {
    final list = await CompanyDataService.loadFromAsset();
    expect(list, isA<List<RecyclerCompany>>());
    expect(list, isNotEmpty);
    // ensure at least one has a website ending with .com
    expect(list.any((c) => c.website.contains('.com')), isTrue);
  });

  test('filter works using loaded company list', () async {
    final companies = await CompanyDataService.loadFromAsset();
    // pick a waste type that exists in the large dataset (e.g. plastic)
    final filtered = RecyclerCompanyService.filterByDetectedWaste(
      'plastic_item',
      source: companies,
    );
    expect(filtered, isNotEmpty);
  });
}
