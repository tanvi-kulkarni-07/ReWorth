// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reworth/main.dart';
import 'package:reworth/providers/auth_provider.dart';
import 'package:reworth/ui/screens/dashboard_screen.dart';
import 'package:reworth/ui/screens/upload_waste_screen.dart';
import 'package:reworth/ui/screens/my_listings_screen.dart';
import 'package:reworth/ui/screens/market_insights_screen.dart';


void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // basic sanity: material app is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('dashboard quick actions navigate', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userNameProvider.overrideWithValue('Tester'),
        ],
        child: MaterialApp(
          home: const DashboardScreen(),
        ),
      ),
    );

    // verify initial DashboardScreen present
    expect(find.byType(DashboardScreen), findsOneWidget);

    // tap upload waste button
    await tester.tap(find.text('➕ Upload Waste'));
    await tester.pumpAndSettle();
    expect(find.byType(UploadWasteScreen), findsOneWidget);

    // go back and try my listings
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    await tester.tap(find.text('📦 My Listings'));
    await tester.pumpAndSettle();
    expect(find.byType(MyListingsScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    await tester.ensureVisible(find.text('📊 Market Insights'));
    await tester.tap(find.text('📊 Market Insights'));
    await tester.pumpAndSettle();
    expect(find.byType(MarketInsightsScreen), findsOneWidget);
  });
}
