import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/recycler_company.dart';

class CompanyDetailsScreen extends StatelessWidget {
  const CompanyDetailsScreen({
    Key? key,
    required this.company,
  }) : super(key: key);

  final RecyclerCompany company;

  Future<void> _openWebsite(BuildContext context) async {
    if (company.website.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No website available for this company')),
      );
      return;
    }

    if (await canLaunchUrlString(company.website)) {
      await launchUrlString(company.website);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(company.name),
        backgroundColor: const Color(0xFF00A699),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Category', company.category),
            _buildDetailRow('Address', company.address),
            _buildDetailRow('City', company.city),
            _buildDetailRow('Waste types', company.wasteTypes.join(', ')),
            _buildDetailRow('Phone', company.phone),
            if (company.website.isNotEmpty) ...[
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => _openWebsite(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A699),
                  ),
                  child: const Text('Visit Official Website'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
