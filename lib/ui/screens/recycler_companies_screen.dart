import 'package:flutter/material.dart';

import '../../models/recycler_company.dart';
import 'company_details_screen.dart';

class RecyclerCompaniesScreen extends StatelessWidget {
  const RecyclerCompaniesScreen({super.key, required this.companies});

  final List<RecyclerCompany> companies;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycling Companies'),
        backgroundColor: const Color(0xFF00A699),
      ),
      body: companies.isEmpty
          ? const Center(child: Text('No companies found for this waste type.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: companies.length,
              itemBuilder: (context, index) {
                final c = companies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(c.name),
                    subtitle: Text('${c.category}\n${c.city}\n${c.phone}'),
                    isThreeLine: true,
                    trailing: Text(c.wasteTypes.join(', ')),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompanyDetailsScreen(company: c),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
