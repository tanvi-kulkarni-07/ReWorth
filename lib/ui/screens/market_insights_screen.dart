import 'package:flutter/material.dart';

class MarketInsightsScreen extends StatelessWidget {
  const MarketInsightsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Insights'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Insights will appear here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
