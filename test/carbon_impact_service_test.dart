import 'package:flutter_test/flutter_test.dart';
import 'package:reworth/services/carbon_impact_service.dart';

void main() {
  test('CO2 calculation uses mapping correctly', () {
    expect(calculateCO2Saved('plastic', 5), 10);
    expect(calculateCO2Saved('paper', 2), 2);
    expect(calculateCO2Saved('metal', 1), 9);
    expect(calculateCO2Saved('glass', 4), 2);
    expect(calculateCO2Saved('organic', 10), 3);
    expect(calculateCO2Saved('unknown', 5), 0);
    expect(calculateCO2Saved('plastic', -1), 0);
  });

  test('carbon credit conversion works', () {
    expect(convertToCarbonCredits(0), 0);
    expect(convertToCarbonCredits(100), 1);
    expect(convertToCarbonCredits(250), 2.5);
  });
}
