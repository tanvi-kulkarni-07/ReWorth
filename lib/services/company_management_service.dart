import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

typedef _HardcodedCompanyRecord = ({
  String id,
  String name,
  String category,
  String address,
  String city,
  LatLng location,
  List<String> wasteTypes,
  String phone,
  String website,
});

class CompanyManagementService {
  CompanyManagementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> upsertCompany({
    required String id,
    required String name,
    required String category,
    required String address,
    required String city,
    required LatLng location,
    required String ownerUid,
    required List<String> wasteTypes,
    String? phone,
    String? website,
    bool isActive = true,
    bool isVerified = true,
  }) {
    return _firestore.collection('companies').doc(id).set({
      'name': name,
      'category': category,
      'address': address,
      'city': city,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'ownerUid': ownerUid,
      'wasteTypes': wasteTypes,
      'phone': phone,
      'website': website,
      'isActive': isActive,
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedDemoCompanies({
    required LatLng center,
    required String ownerUid,
  }) async {
    final companies = _buildHardcodedCompanies(center);

    final batch = _firestore.batch();

    for (final company in companies) {
      final docRef = _firestore.collection('companies').doc(company.id);
      batch.set(docRef, {
        'name': company.name,
        'category': company.category,
        'address': company.address,
        'city': company.city,
        'location': {
          'latitude': company.location.latitude,
          'longitude': company.location.longitude,
        },
        'ownerUid': ownerUid,
        'wasteTypes': company.wasteTypes,
        'phone': company.phone,
        'website': company.website,
        'isActive': true,
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // Edit this list when you want to change the hardcoded companies
  // that are written to Firestore.
  List<_HardcodedCompanyRecord> _buildHardcodedCompanies(LatLng _) {
    return [
      (
        id: 'ecogreen_recycling_mumbai',
        name: 'EcoGreen Recycling Pvt Ltd',
        category: 'Recycling center',
        address: 'Plot 18, MIDC Industrial Area, Andheri East',
        city: 'Mumbai',
        location: const LatLng(19.1176, 72.8647),
        wasteTypes: const ['plastic', 'paper', 'glass', 'cardboard'],
        phone: '+91 9876541201',
        website: 'https://ecogreenrecycling.in',
      ),
      (
        id: 'pune_metal_scrap_traders',
        name: 'Pune Metal Scrap Traders',
        category: 'Scrap buyer',
        address: 'Gat No 214, Bhosari Industrial Area',
        city: 'Pune',
        location: const LatLng(18.6298, 73.8416),
        wasteTypes: const ['metal', 'batteries'],
        phone: '+91 9823045612',
        website: 'https://punescraptraders.com',
      ),
      (
        id: 'nagpur_e_waste_recyclers',
        name: 'Nagpur E-Waste Recyclers',
        category: 'Recycling center',
        address: 'Plot 54, Hingna MIDC',
        city: 'Nagpur',
        location: const LatLng(21.0873, 79.0421),
        wasteTypes: const ['e-waste', 'batteries', 'metal'],
        phone: '+91 9765412398',
        website: 'https://nagpurewaste.com',
      ),
      (
        id: 'nashik_green_waste_solutions',
        name: 'Nashik Green Waste Solutions',
        category: 'Waste management company',
        address: 'Ambad MIDC, Pathardi Phata',
        city: 'Nashik',
        location: const LatLng(19.9596, 73.7537),
        wasteTypes: const ['plastic', 'paper', 'cardboard', 'glass'],
        phone: '+91 9881023345',
        website: 'https://nashikgreenwaste.com',
      ),
      (
        id: 'thane_scrap_yard',
        name: 'Thane Scrap Yard',
        category: 'Scrap yard',
        address: 'Road No 16, Wagle Industrial Estate',
        city: 'Thane',
        location: const LatLng(19.2040, 72.9720),
        wasteTypes: const ['metal', 'plastic'],
        phone: '+91 9819987123',
        website: 'https://thanescrapyard.in',
      ),
      (
        id: 'aurangabad_recycling_hub',
        name: 'Aurangabad Recycling Hub',
        category: 'Recycling center',
        address: 'Chikalthana MIDC, Plot 22',
        city: 'Aurangabad',
        location: const LatLng(19.8762, 75.3433),
        wasteTypes: const ['plastic', 'paper', 'glass'],
        phone: '+91 9405123488',
        website: 'https://aurangabadrecycling.com',
      ),
      (
        id: 'kolhapur_metal_buyers',
        name: 'Kolhapur Metal Buyers',
        category: 'Scrap buyer',
        address: 'Shiroli MIDC Industrial Area',
        city: 'Kolhapur',
        location: const LatLng(16.7050, 74.2433),
        wasteTypes: const ['metal', 'batteries'],
        phone: '+91 9422408899',
        website: 'https://kolhapurmetalbuyers.in',
      ),
      (
        id: 'solapur_eco_waste_management',
        name: 'Solapur Eco Waste Management',
        category: 'Waste management company',
        address: 'Hotgi Road Industrial Zone',
        city: 'Solapur',
        location: const LatLng(17.6599, 75.9064),
        wasteTypes: const ['plastic', 'paper', 'cardboard'],
        phone: '+91 9881345690',
        website: 'https://solapurecowaste.com',
      ),
      (
        id: 'amravati_scrap_traders',
        name: 'Amravati Scrap Traders',
        category: 'Scrap buyer',
        address: 'Badnera Industrial Area',
        city: 'Amravati',
        location: const LatLng(20.9333, 77.7513),
        wasteTypes: const ['metal', 'plastic'],
        phone: '+91 9763224588',
        website: 'https://amravatiscrap.com',
      ),
      (
        id: 'nanded_recycling_point',
        name: 'Nanded Recycling Point',
        category: 'Recycling center',
        address: 'CIDCO Industrial Layout',
        city: 'Nanded',
        location: const LatLng(19.1383, 77.3210),
        wasteTypes: const ['paper', 'plastic', 'glass', 'cardboard'],
        phone: '+91 9421834567',
        website: 'https://nandedrecycling.in',
      ),
      (
        id: 'mumbai_industrial_scrap_yard',
        name: 'Mumbai Industrial Scrap Yard',
        category: 'Scrap yard',
        address: 'Reay Road Dockyard Area',
        city: 'Mumbai',
        location: const LatLng(18.9765, 72.8442),
        wasteTypes: const ['metal', 'plastic', 'e-waste'],
        phone: '+91 9930123456',
        website: 'https://mumbaiscrapyard.com',
      ),
      (
        id: 'pune_e_waste_collection_center',
        name: 'Pune E-Waste Collection Center',
        category: 'Recycling center',
        address: 'Baner Pashan Link Road',
        city: 'Pune',
        location: const LatLng(18.5590, 73.7868),
        wasteTypes: const ['e-waste', 'batteries', 'metal'],
        phone: '+91 9822113344',
        website: 'https://puneewastecenter.com',
      ),
      (
        id: 'thane_green_recycling_services',
        name: 'Thane Green Recycling Services',
        category: 'Waste management company',
        address: 'Ghodbunder Road Industrial Area',
        city: 'Thane',
        location: const LatLng(19.2700, 72.9654),
        wasteTypes: const ['plastic', 'paper', 'glass', 'cardboard'],
        phone: '+91 9892345566',
        website: 'https://thanegreenrecycling.com',
      ),
      (
        id: 'nagpur_scrap_hub',
        name: 'Nagpur Scrap Hub',
        category: 'Scrap yard',
        address: 'Kalamna Market Road',
        city: 'Nagpur',
        location: const LatLng(21.1522, 79.1385),
        wasteTypes: const ['metal', 'plastic', 'batteries'],
        phone: '+91 9373101122',
        website: 'https://nagpurscraphub.com',
      ),
      (
        id: 'nashik_eco_scrap_buyers',
        name: 'Nashik Eco Scrap Buyers',
        category: 'Scrap buyer',
        address: 'Satpur MIDC Industrial Estate',
        city: 'Nashik',
        location: const LatLng(19.9975, 73.7317),
        wasteTypes: const ['metal', 'paper', 'cardboard'],
        phone: '+91 9860557722',
        website: 'https://nashikscrapbuyers.in',
      ),
    ];
  }
}
