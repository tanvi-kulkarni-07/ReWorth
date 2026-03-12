import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Mapping of waste types to kilograms of CO2 saved per kilogram of material
/// recycled.  These constants are used throughout the app when computing the
/// environmental impact of a user action.
const Map<String, double> co2SavingsMap = {
  'plastic': 2.0,
  'paper': 1.0,
  'metal': 9.0,
  'glass': 0.5,
  'organic': 0.3,
};

/// Returns the number of kilograms of CO2 saved by recycling [weightKg] of
/// [wasteType].  If the waste type is unrecognised or weight is non‑positive,
/// zero is returned.
double calculateCO2Saved(String wasteType, double weightKg) {
  if (wasteType.isEmpty || weightKg <= 0) {
    return 0.0;
  }
  final key = wasteType.toLowerCase();
  final per = co2SavingsMap[key] ?? 0.0;
  return per * weightKg;
}

/// Converts [co2Saved] (kilograms) into carbon credits using the rule:
/// 100 kg CO₂ = 1 credit.  The result is a double; callers may round up or
/// down as needed.
double convertToCarbonCredits(double co2Saved) {
  if (co2Saved <= 0) return 0.0;
  return co2Saved / 100.0;
}

/// Record recycling activity in Firestore.  This function will create a document
/// in `recyclingTransactions` and update the corresponding user record with
/// atomic increments.  If the user document does not yet exist it will be
/// initialised with zero values so that the increments succeed.
///
/// Throws on failure; callers should catch and show an error message.
Future<void> recordRecyclingTransaction({
  required String wasteType,
  required double weightKg,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No authenticated user');
  }
  final uid = user.uid;

  if (wasteType.isEmpty) {
    throw Exception('wasteType is required');
  }
  if (weightKg <= 0) {
    throw Exception('weightKg must be positive');
  }

  final co2 = calculateCO2Saved(wasteType, weightKg);
  final credits = convertToCarbonCredits(co2);

  final db = FirebaseFirestore.instance;
  final txCol = db.collection('recyclingTransactions');
  final userRef = db.collection('users').doc(uid);

  try {
    // transaction document
    await txCol.add({
      'userId': uid,
      'wasteType': wasteType,
      'weightKg': weightKg,
      'co2Saved': co2,
      'carbonCreditsEarned': credits,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ensure user document exists
    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      await userRef.set({
        'totalWasteRecycled': 0,
        'totalCO2Saved': 0,
        'carbonCredits': 0,
      });
    }

    await userRef.update({
      'totalWasteRecycled': FieldValue.increment(weightKg),
      'totalCO2Saved': FieldValue.increment(co2),
      'carbonCredits': FieldValue.increment(credits),
    });
  } catch (e) {
    // propagate error after logging
    debugPrint('recordRecyclingTransaction error: $e');
    rethrow;
  }
}

/// Returns the current impact statistics for the specified user.  This helper
/// is used by the dashboard to display the user's cumulative impact.
Future<Map<String, double>> getUserImpactStats(String userId) async {
  if (userId.isEmpty) {
    return {
      'totalWasteRecycled': 0,
      'totalCO2Saved': 0,
      'carbonCredits': 0,
    };
  }
  final ref = FirebaseFirestore.instance.collection('users').doc(userId);
  final snap = await ref.get();
  if (!snap.exists) {
    return {
      'totalWasteRecycled': 0,
      'totalCO2Saved': 0,
      'carbonCredits': 0,
    };
  }
  final data = snap.data()!;
  return {
    'totalWasteRecycled': (data['totalWasteRecycled'] as num?)?.toDouble() ?? 0,
    'totalCO2Saved': (data['totalCO2Saved'] as num?)?.toDouble() ?? 0,
    'carbonCredits': (data['carbonCredits'] as num?)?.toDouble() ?? 0,
  };
}
