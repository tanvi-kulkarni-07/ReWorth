import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/impact_stats.dart';
import '../services/carbon_impact_service.dart';

// simple state providers to hold dashboard data (legacy/fallback)
final totalWasteProvider = StateProvider<int>((ref) => 245);
final carbonSavedProvider = StateProvider<int>((ref) => 128);
final earningsProvider = StateProvider<double>((ref) => 12450);

// impact stats pulled from Firestore for the current user.  The StreamProvider
// listens to the `users/{uid}` document and maps it to an ImpactStats object.
final impactStatsProvider = StreamProvider<ImpactStats>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return const Stream.empty();
  }
  final docSnap =
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  return docSnap.map((snap) =>
      snap.exists ? ImpactStats.fromMap(snap.data()!) : const ImpactStats(totalWasteRecycled: 0, totalCO2Saved: 0, carbonCredits: 0));
});

final aiSuggestionsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [
    {
      'text': '🌾 Banana fiber demand is high in your region.',
      'tag': 'Trending Now',
      'color': Colors.green,
    },
    {
      'text': '♻️ Plastic prices increased by 5%.',
      'tag': 'Price Alert',
      'color': Colors.blue,
    },
  ],
);
