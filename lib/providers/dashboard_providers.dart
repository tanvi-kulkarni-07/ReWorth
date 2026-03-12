import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openrouter_service.dart';

// simple state providers to hold dashboard data
final dashboardTotalWasteProvider = StateProvider<int>((ref) => 245);
final dashboardCarbonSavedProvider = StateProvider<int>((ref) => 128);
final dashboardEarningsProvider = StateProvider<double>((ref) => 12450);

final realTimeAISuggestionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final openRouter = OpenRouterService();

      const prompt = """
  Generate 8 short, real-time recycling market insights, environmental tips, and waste management trends for a user dashboard.
  Ensure variety across:
  - Global recycling market trends (prices of plastic, paper, metal).
  - Practical daily life recycling tips.
  - Environmental impact facts.
  - Potential earnings opportunities in the local economy.
  - Future tech in waste management.
  
  Return ONLY a JSON array of 8 objects with 'text', 'tag', and 'color_hex' keys.
  Example: [{"text": "Plastic prices up 5%", "tag": "MARKET", "color_hex": "FF2196F3"}]
  Colors should be hex strings (AARRGGBB). Keep texts under 60 characters.
  """;

      try {
        final response = await openRouter.ask(prompt);
        // Find the JSON block if AI includes extra text
        final startIndex = response.indexOf('[');
        final endIndex = response.lastIndexOf(']') + 1;
        if (startIndex == -1 || endIndex == -1)
          throw Exception("Invalid AI response");

        final jsonStr = response.substring(startIndex, endIndex);
        final List<dynamic> data = jsonDecode(jsonStr);

        return data.map((item) {
          return {
            'text': item['text'] ?? 'New insight available',
            'tag': item['tag'] ?? 'INSIGHT',
            'color': Color(
              int.parse(item['color_hex'] ?? 'FF4CAF50', radix: 16),
            ),
          };
        }).toList();
      } catch (e) {
        // Fallback if AI fails (providing 8 static suggestions)
        return [
          {
            'text': '♻️ Recycle plastic bottles (PET) for max rewards.',
            'tag': 'EARNINGS',
            'color': const Color(0xFF4CAF50),
          },
          {
            'text': 'Market: Copper scrap prices are up by 4% globally.',
            'tag': 'MARKET',
            'color': const Color(0xFF2196F3),
          },
          {
            'text': 'Tip: Rinse containers before putting them in the bin.',
            'tag': 'ECO-TIP',
            'color': const Color(0xFFFF9800),
          },
          {
            'text': 'Fun Fact: Recycled glass uses 40% less energy.',
            'tag': 'FACT',
            'color': const Color(0xFF9C27B0),
          },
          {
            'text': 'Local Event: E-waste collection drive this Saturday!',
            'tag': 'LOCAL',
            'color': const Color(0xFFF44336),
          },
          {
            'text': 'Insight: Paper demand is rising in manufacturing.',
            'tag': 'MARKET',
            'color': const Color(0xFF795548),
          },
          {
            'text': 'Zero-Waste: Use cloth bags for bulk shopping.',
            'tag': 'LIFESTYLE',
            'color': const Color(0xFF009688),
          },
          {
            'text': 'Eco Hero: You saved 12kg CO2 this week!',
            'tag': 'PROGRESS',
            'color': const Color(0xFFE91E63),
          },
        ];
      }
    });
