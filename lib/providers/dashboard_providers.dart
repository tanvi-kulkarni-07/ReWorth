import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// simple state providers to hold dashboard data
final totalWasteProvider = StateProvider<int>((ref) => 245);
final carbonSavedProvider = StateProvider<int>((ref) => 128);
final earningsProvider = StateProvider<double>((ref) => 12450);
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
