import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reworth/services/company_data_service.dart';
import 'package:reworth/services/recycler_company_service.dart';
import 'package:reworth/models/recycler_company.dart';
import 'package:reworth/ui/screens/upload_waste_screen.dart';
import 'package:latlong2/latlong.dart';

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

  testWidgets('upload screen shows company cards with price after detection',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: UploadWasteScreen()),
      ),
    );

    // retrieve state as dynamic since the class is private
    final state = tester.state(find.byType(UploadWasteScreen));

    // create a fake company that accepts plastic
    final sample = RecyclerCompany(
      id: 'foo',
      name: 'Foo Recycling',
      category: 'Recycler',
      address: 'Addr',
      city: 'City',
      wasteTypes: const ['plastic'],
      phone: '12345',
      website: 'foo.com',
      isActive: true,
      isVerified: true,
      location: const LatLng(0, 0),
    );

    // simulate detection and filtering using dynamic to access testing helpers
    final dyn = state as dynamic;
    dyn.testSetDetectedMaterial('plastic');
    dyn.testSetFilteredCompanies([sample]);
    // move to detect step so the results are visible
    dyn.testSetCurrentStep(1);
    await tester.pump();

    // card should appear with name and pricing info
    expect(find.text('Foo Recycling'), findsOneWidget);
    expect(find.text('Price/kg: ₹20/kg'), findsOneWidget);
    expect(find.text('Phone: 12345'), findsOneWidget);
    expect(find.text('Website: foo.com'), findsOneWidget);

    // move to price step and verify weight entry & total calculation
    dyn.testSetCurrentStep(2);
    await tester.pump();
    expect(find.text('Estimated value for 1 kg: ₹20'), findsOneWidget);

    // simulate entering weight
    dyn.testSetEnteredWeight(2.0);
    await tester.pump();
    expect(find.text('Total estimate: ₹40'), findsOneWidget);

    // go to buyers step and ensure card is visible
    dyn.testSetCurrentStep(3);
    await tester.pump();
    expect(find.text('Foo Recycling'), findsOneWidget);

    // enter weight into card and view details
    await tester.enterText(find.byType(TextField).first, '3');
    await tester.pump();
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();

    // verify company detail page
    expect(find.text('Foo Recycling'), findsOneWidget);
    expect(find.text('Phone: 12345'), findsOneWidget);
    expect(find.text('Website: foo.com'), findsOneWidget);
    expect(find.text('Price per kg: ₹20/kg'), findsOneWidget);
    expect(find.text('Entered weight: 3.00 kg'), findsOneWidget);
    expect(find.text('Estimated value: ₹60'), findsOneWidget);
  });}
