import 'package:flutter/material.dart';
import '../../models/recycler_company.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CompanyDetailScreen extends StatelessWidget {
  final RecyclerCompany company;
  final double weight;
  final double totalValue;
  final double pricePerKg;

  const CompanyDetailScreen({
    super.key,
    required this.company,
    required this.weight,
    required this.totalValue,
    required this.pricePerKg,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Details'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Category: ${company.category}'),
            Text('City: ${company.city}'),
            const SizedBox(height: 8),
            Text('Phone: ${company.phone}'),
            Text('Website: ${company.website}'),
            const SizedBox(height: 16),
            Text('Price per kg: ₹${pricePerKg.toStringAsFixed(0)}/kg'),
            Text('Entered weight: ${weight.toStringAsFixed(2)} kg'),
            Text('Estimated value: ₹${totalValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final sanitized = company.phone.replaceAll(RegExp(r"\s+"), "");
                      final uri = 'tel:$sanitized';
                      if (await canLaunchUrlString(uri)) {
                        await launchUrlString(uri);
                      }
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Company'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A699),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      var url = company.website;
                      if (!url.startsWith('http')) url = 'https://$url';
                      if (await canLaunchUrlString(url)) {
                        await launchUrlString(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.language),
                    label: const Text('Visit Website'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A699),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
