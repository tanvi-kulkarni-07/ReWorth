import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a waste management company that can accept requests from sellers.
class Company {
  final String name;
  final String category;
  final List<String> wasteTypes;
  final String phone;
  final String website;
  final String address;
  final String city;
  final Map<String, double> location;
  final bool isActive;
  final bool isVerified;
  final String ownerUid;
  final String updatedAt;

  Company({
    required this.name,
    required this.category,
    required this.wasteTypes,
    required this.phone,
    required this.website,
    required this.address,
    required this.city,
    required this.location,
    required this.isActive,
    required this.isVerified,
    required this.ownerUid,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'],
      category: json['category'],
      wasteTypes: List<String>.from(json['wasteTypes']),
      phone: json['phone'],
      website: json['website'],
      address: json['address'],
      city: json['city'],
      location: Map<String, double>.from(json['location']),
      isActive: json['isActive'],
      isVerified: json['isVerified'],
      ownerUid: json['ownerUid'],
      updatedAt: json['updatedAt'],
    );
  }
}

/// List of predefined waste management companies.
final List<Company> companies = [
  Company.fromJson({
    "name": "Recykal",
    "category": "Digital Waste Management",
    "wasteTypes": ["plastic", "paper", "metal", "electronics"],
    "phone": "+91 40 4855 3333",
    "website": "https://recykal.com",
    "address": "HITEC City",
    "city": "Hyderabad",
    "location": {"latitude": 17.4435, "longitude": 78.3772},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "Attero Recycling",
    "category": "E-Waste Recycling",
    "wasteTypes": ["electronics", "battery", "metal"],
    "phone": "+91 120 466 7700",
    "website": "https://attero.in",
    "address": "Sector 80",
    "city": "Noida",
    "location": {"latitude": 28.5355, "longitude": 77.3910},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "Eco Recycling Ltd",
    "category": "E-Waste Recycling",
    "wasteTypes": ["electronics", "plastic", "metal"],
    "phone": "+91 22 4005 2951",
    "website": "https://ecoreco.com",
    "address": "Andheri East",
    "city": "Mumbai",
    "location": {"latitude": 19.1136, "longitude": 72.8697},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "Saahas Zero Waste",
    "category": "Waste Management",
    "wasteTypes": ["plastic", "paper", "organic"],
    "phone": "+91 80 4168 9899",
    "website": "https://saahas.org",
    "address": "Indiranagar",
    "city": "Bengaluru",
    "location": {"latitude": 12.9719, "longitude": 77.6412},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "Ramky Enviro Engineers",
    "category": "Environmental Services",
    "wasteTypes": ["industrial", "hazardous", "plastic"],
    "phone": "+91 40 2301 6000",
    "website": "https://ramkyenviroengineers.com",
    "address": "Gachibowli",
    "city": "Hyderabad",
    "location": {"latitude": 17.4401, "longitude": 78.3489},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "Hulladek Recycling",
    "category": "E-Waste Recycling",
    "wasteTypes": ["electronics", "battery", "metal"],
    "phone": "+91 33 4005 6000",
    "website": "https://hulladek.com",
    "address": "Salt Lake Sector V",
    "city": "Kolkata",
    "location": {"latitude": 22.5726, "longitude": 88.3639},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "Clean Harbors India",
    "category": "Waste Management",
    "wasteTypes": ["industrial", "hazardous"],
    "phone": "+91 80 6734 3000",
    "website": "https://cleanharbors.com",
    "address": "Whitefield",
    "city": "Bengaluru",
    "location": {"latitude": 12.9698, "longitude": 77.7500},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "Gem Enviro Management",
    "category": "E-Waste Recycling",
    "wasteTypes": ["electronics", "metal", "plastic"],
    "phone": "+91 44 2793 3333",
    "website": "https://gemrecycling.com",
    "address": "Ambattur Industrial Estate",
    "city": "Chennai",
    "location": {"latitude": 13.0983, "longitude": 80.1622},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "TrashCon",
    "category": "Waste Technology",
    "wasteTypes": ["plastic", "mixed", "municipal"],
    "phone": "+91 80 4680 9100",
    "website": "https://trashcon.in",
    "address": "HSR Layout",
    "city": "Bengaluru",
    "location": {"latitude": 12.9121, "longitude": 77.6446},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
  Company.fromJson({
    "name": "Paperman Recycling",
    "category": "Paper Recycling",
    "wasteTypes": ["paper", "cardboard"],
    "phone": "+91 44 4214 3030",
    "website": "https://paperman.in",
    "address": "Anna Nagar",
    "city": "Chennai",
    "location": {"latitude": 13.0827, "longitude": 80.2707},
    "isActive": true,
    "isVerified": true,
    "ownerUid": "firebase-auth-user-id",
    "updatedAt": "server timestamp"
  }),
];

/// Represents a waste listing created by a seller.
class WasteListing {
  final String wasteType;
  final double weightKg;
  final double pricePerKg;
  final double totalValue;
  final String companyName;
  final String sellerName;
  final String sellerLocation;
  final String contactPhone;
  String status; // "available", "request_sent", "request_accepted", ...
  String? buyerName;
  String? pickupRequestId;
  DateTime? requestSentAt;
  DateTime? requestAcceptedAt;

  WasteListing({
    required this.wasteType,
    required this.weightKg,
    required this.pricePerKg,
    required this.totalValue,
    required this.companyName,
    required this.sellerName,
    required this.sellerLocation,
    required this.contactPhone,
    this.status = 'available',
    this.buyerName,
    this.pickupRequestId,
    this.requestSentAt,
    this.requestAcceptedAt,
  });

  Map<String, dynamic> toJson() => {
        'wasteType': wasteType,
        'weightKg': weightKg,
        'pricePerKg': pricePerKg,
        'totalValue': totalValue,
        'companyName': companyName,
        'sellerName': sellerName,
        'sellerLocation': sellerLocation,
        'contactPhone': contactPhone,
        'status': status,
        'buyerName': buyerName,
        'pickupRequestId': pickupRequestId,
        'requestSentAt': requestSentAt?.toIso8601String(),
        'requestAcceptedAt': requestAcceptedAt?.toIso8601String(),
      };

  factory WasteListing.fromJson(Map<String, dynamic> json) {
    return WasteListing(
      wasteType: json['wasteType'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      companyName: json['companyName'] as String,
      sellerName: json['sellerName'] as String,
      sellerLocation: json['sellerLocation'] as String,
      contactPhone: json['contactPhone'] as String? ?? '',
      status: json['status'] as String? ?? 'available',      buyerName: json['buyerName'] as String?,
      pickupRequestId: json['pickupRequestId'] as String?,
      requestSentAt: json['requestSentAt'] != null
          ? DateTime.parse(json['requestSentAt'] as String)
          : null,
      requestAcceptedAt: json['requestAcceptedAt'] != null
          ? DateTime.parse(json['requestAcceptedAt'] as String)
          : null,
    );
  }
}

/// Notifier that manages a list of [WasteListing] and persists it to prefs.
class ListingsNotifier extends StateNotifier<List<WasteListing>> {
  SharedPreferences? _prefs;

  ListingsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString('listings');
    if (raw != null) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        state = list
            .map((e) => WasteListing.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    } else {
      // Add dummy listings for demonstration
      state = [
        // Plastic Waste
        WasteListing(
          wasteType: 'Plastic',
          weightKg: 2000,
          pricePerKg: 20,
          totalValue: 40000,
          companyName: 'EcoPlastic Industries',
          sellerName: 'Rahul Patil',
          sellerLocation: 'Pune',
          contactPhone: '9876543210',
        ),
        WasteListing(
          wasteType: 'Plastic',
          weightKg: 1500,
          pricePerKg: 20,
          totalValue: 30000,
          companyName: 'Green Recycling Ltd',
          sellerName: 'Sneha Kulkarni',
          sellerLocation: 'Mumbai',
          contactPhone: '9823456712',
        ),
        WasteListing(
          wasteType: 'Plastic',
          weightKg: 3000,
          pricePerKg: 20,
          totalValue: 60000,
          companyName: 'Plastic Waste Solutions',
          sellerName: 'Amit Sharma',
          sellerLocation: 'Nashik',
          contactPhone: '9765432109',
        ),
        WasteListing(
          wasteType: 'Plastic',
          weightKg: 2200,
          pricePerKg: 20,
          totalValue: 44000,
          companyName: 'EcoFriendly Plastics',
          sellerName: 'Priya Deshmukh',
          sellerLocation: 'Pune',
          contactPhone: '9898765432',
        ),
        // Metal Waste
        WasteListing(
          wasteType: 'Metal',
          weightKg: 1800,
          pricePerKg: 40,
          totalValue: 72000,
          companyName: 'Metal Recyclers Inc',
          sellerName: 'Karan Mehta',
          sellerLocation: 'Thane',
          contactPhone: '9812345678',
        ),
        WasteListing(
          wasteType: 'Metal',
          weightKg: 2500,
          pricePerKg: 40,
          totalValue: 100000,
          companyName: 'Steel & Metal Works',
          sellerName: 'Neha Jadhav',
          sellerLocation: 'Aurangabad',
          contactPhone: '9776543210',
        ),
        WasteListing(
          wasteType: 'Metal',
          weightKg: 3500,
          pricePerKg: 40,
          totalValue: 140000,
          companyName: 'Metal Processing Co',
          sellerName: 'Rohit Gupta',
          sellerLocation: 'Nagpur',
          contactPhone: '9867543210',
        ),
        WasteListing(
          wasteType: 'Metal',
          weightKg: 1200,
          pricePerKg: 40,
          totalValue: 48000,
          companyName: 'Scrap Metal Traders',
          sellerName: 'Pooja Shinde',
          sellerLocation: 'Kolhapur',
          contactPhone: '9887654321',
        ),
        // Paper Waste
        WasteListing(
          wasteType: 'Paper',
          weightKg: 2700,
          pricePerKg: 12,
          totalValue: 32400,
          companyName: 'Paper Recycling Hub',
          sellerName: 'Vivek Nair',
          sellerLocation: 'Pune',
          contactPhone: '9798765432',
        ),
        WasteListing(
          wasteType: 'Paper',
          weightKg: 1900,
          pricePerKg: 12,
          totalValue: 22800,
          companyName: 'Green Paper Mills',
          sellerName: 'Anjali Verma',
          sellerLocation: 'Mumbai',
          contactPhone: '9845671234',
        ),
        WasteListing(
          wasteType: 'Paper',
          weightKg: 2300,
          pricePerKg: 12,
          totalValue: 27600,
          companyName: 'Paper Waste Solutions',
          sellerName: 'Sagar Pawar',
          sellerLocation: 'Satara',
          contactPhone: '9871234567',
        ),
        WasteListing(
          wasteType: 'Paper',
          weightKg: 1400,
          pricePerKg: 12,
          totalValue: 16800,
          companyName: 'EcoPaper Recyclers',
          sellerName: 'Riya Singh',
          sellerLocation: 'Pune',
          contactPhone: '9834567890',
        ),
        // E-Waste
        WasteListing(
          wasteType: 'E-Waste',
          weightKg: 3200,
          pricePerKg: 50,
          totalValue: 160000,
          companyName: 'E-Waste Specialists',
          sellerName: 'Mohit Agarwal',
          sellerLocation: 'Delhi',
          contactPhone: '9811122233',
        ),
        WasteListing(
          wasteType: 'E-Waste',
          weightKg: 1600,
          pricePerKg: 50,
          totalValue: 80000,
          companyName: 'Electronic Recycling Co',
          sellerName: 'Kavita Joshi',
          sellerLocation: 'Nashik',
          contactPhone: '9891234567',
        ),
        WasteListing(
          wasteType: 'E-Waste',
          weightKg: 2100,
          pricePerKg: 50,
          totalValue: 105000,
          companyName: 'Tech Waste Solutions',
          sellerName: 'Aditya Kulkarni',
          sellerLocation: 'Pune',
          contactPhone: '9823344556',
        ),
        // Dummy listings with company acknowledgments
        WasteListing(
          wasteType: 'Plastic',
          weightKg: 1000,
          pricePerKg: 20,
          totalValue: 20000,
          companyName: 'EcoPlastic Industries',
          sellerName: 'Rahul Patil',
          sellerLocation: 'Pune',
          contactPhone: '9876543210',
          status: 'request_accepted',
          buyerName: 'Recykal',
          requestAcceptedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        WasteListing(
          wasteType: 'Metal',
          weightKg: 800,
          pricePerKg: 40,
          totalValue: 32000,
          companyName: 'Metal Recyclers Inc',
          sellerName: 'Karan Mehta',
          sellerLocation: 'Thane',
          contactPhone: '9812345678',
          status: 'request_accepted',
          buyerName: 'Attero Recycling',
          requestAcceptedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        WasteListing(
          wasteType: 'Paper',
          weightKg: 1200,
          pricePerKg: 12,
          totalValue: 14400,
          companyName: 'Paper Recycling Hub',
          sellerName: 'Vivek Nair',
          sellerLocation: 'Pune',
          contactPhone: '9798765432',
          status: 'request_accepted',
          buyerName: 'Saahas Zero Waste',
          requestAcceptedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        WasteListing(
          wasteType: 'E-Waste',
          weightKg: 500,
          pricePerKg: 50,
          totalValue: 25000,
          companyName: 'E-Waste Specialists',
          sellerName: 'Mohit Agarwal',
          sellerLocation: 'Delhi',
          contactPhone: '9811122233',
          status: 'request_accepted',
          buyerName: 'Eco Recycling Ltd',
          requestAcceptedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];
      await _save();
    }
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = json.encode(state.map((e) => e.toJson()).toList());
    await _prefs!.setString('listings', encoded);
  }

  void addListing(WasteListing listing) {
    state = [...state, listing];
    _save();
  }

  void updateListing(int index, WasteListing updated) {
    final copy = [...state];
    if (index >= 0 && index < copy.length) {
      copy[index] = updated;
      state = copy;
      _save();
    }
  }

  void updateListingStatus(
    String sellerName,
    String wasteType,
    String status, {
    String? buyerName,
    String? pickupRequestId,
    DateTime? sentAt,
    DateTime? acceptedAt,
  }) {
    final copy = [...state];
    for (var i = 0; i < copy.length; i++) {
      if (copy[i].sellerName == sellerName && copy[i].wasteType == wasteType) {
        copy[i] = WasteListing(
          wasteType: copy[i].wasteType,
          weightKg: copy[i].weightKg,
          pricePerKg: copy[i].pricePerKg,
          totalValue: copy[i].totalValue,
          companyName: copy[i].companyName,
          sellerName: copy[i].sellerName,
          sellerLocation: copy[i].sellerLocation,
          contactPhone: copy[i].contactPhone,
          status: status,
          buyerName: buyerName ?? copy[i].buyerName,
          pickupRequestId: pickupRequestId ?? copy[i].pickupRequestId,
          requestSentAt: sentAt ?? copy[i].requestSentAt,
          requestAcceptedAt: acceptedAt ?? copy[i].requestAcceptedAt,
        );
        break;
      }
    }
    state = copy;
    _save();
  }
}

/// A simple pickup request generated when a seller chooses a company.
class PickupRequest {
  final String sellerId;
  final String sellerName;
  final String wasteType;
  final double weight;
  final String companyName;
  final double companyLat;
  final double companyLng;
  final double sellerLat;
  final double sellerLng;
  String status; // pending, accepted, in_transit, completed

  PickupRequest({
    required this.sellerId,
    required this.sellerName,
    required this.wasteType,
    required this.weight,
    required this.companyName,
    required this.companyLat,
    required this.companyLng,
    required this.sellerLat,
    required this.sellerLng,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'wasteType': wasteType,
        'weight': weight,
        'companyName': companyName,
        'companyLat': companyLat,
        'companyLng': companyLng,
        'sellerLat': sellerLat,
        'sellerLng': sellerLng,
        'status': status,
      };

  factory PickupRequest.fromJson(Map<String, dynamic> json) {
    return PickupRequest(
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      wasteType: json['wasteType'] as String,
      weight: (json['weight'] as num).toDouble(),
      companyName: json['companyName'] as String,
      companyLat: (json['companyLat'] as num).toDouble(),
      companyLng: (json['companyLng'] as num).toDouble(),
      sellerLat: (json['sellerLat'] as num).toDouble(),
      sellerLng: (json['sellerLng'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class PickupRequestsNotifier extends StateNotifier<List<PickupRequest>> {
  SharedPreferences? _prefs;

  PickupRequestsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString('pickup_requests');
    if (raw != null) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        state = list
            .map((e) => PickupRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = json.encode(state.map((e) => e.toJson()).toList());
    await _prefs!.setString('pickup_requests', encoded);
  }

  void addRequest(PickupRequest req) {
    state = [...state, req];
    _save();
  }
}

/// Represents an order placed by a buyer when they interact with a listing.
class Order {
  final String wasteType;
  final double weight;
  final String sellerName;
  final String companyName;
  final String sellerLocation;
  String status;
  final String pickupLocation;
  final String pickupDate;
  final String pickupTime;
  final String progressStatus;
  final String contactPhone;

  Order({
    required this.wasteType,
    required this.weight,
    required this.sellerName,
    required this.companyName,
    required this.sellerLocation,
    this.status = 'pending',
    this.pickupLocation = '',
    this.pickupDate = '',
    this.pickupTime = '',
    this.progressStatus = '',
    this.contactPhone = '',
  });

  Map<String, dynamic> toJson() => {
        'wasteType': wasteType,
        'weight': weight,
        'sellerName': sellerName,
        'companyName': companyName,
        'sellerLocation': sellerLocation,
        'status': status,
        'pickupLocation': pickupLocation,
        'pickupDate': pickupDate,
        'pickupTime': pickupTime,
        'progressStatus': progressStatus,
        'contactPhone': contactPhone,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      wasteType: json['wasteType'] as String,
      weight: (json['weight'] as num).toDouble(),
      sellerName: json['sellerName'] as String,
      companyName: json['companyName'] as String,
      sellerLocation: json['sellerLocation'] as String,
      status: json['status'] as String? ?? 'pending',
      pickupLocation: json['pickupLocation'] as String? ?? '',
      pickupDate: json['pickupDate'] as String? ?? '',
      pickupTime: json['pickupTime'] as String? ?? '',
      progressStatus: json['progressStatus'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
    );
  }
}

class OrdersNotifier extends StateNotifier<List<Order>> {
  SharedPreferences? _prefs;

  OrdersNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString('orders');
    if (raw != null) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        state = list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        state = [];
      }
    } else {
      // Provide some sample orders for buyers to see in the UI.
      state = [
        Order(
          wasteType: 'Plastic Waste',
          weight: 2500,
          sellerName: 'Arjun More',
          companyName: 'Plastic Waste Solutions',
          sellerLocation: 'Pune',
          contactPhone: '9823415678',
          status: 'pending',
        ),
        Order(
          wasteType: 'Metal Waste',
          weight: 1800,
          sellerName: 'Kavya Patil',
          companyName: 'Metal Recyclers Inc.',
          sellerLocation: 'Mumbai',
          contactPhone: '9765432198',
          status: 'pending',
        ),
        Order(
          wasteType: 'Paper Waste',
          weight: 3000,
          sellerName: 'Rohan Jadhav',
          companyName: 'Paper Recycling Hub',
          sellerLocation: 'Nashik',
          contactPhone: '9876123450',
          status: 'pending',
        ),
        Order(
          wasteType: 'E-Waste',
          weight: 1200,
          sellerName: 'Snehal Desai',
          companyName: 'E-Waste Specialists',
          sellerLocation: 'Pune',
          contactPhone: '9890345671',
          status: 'pending',
        ),
        Order(
          wasteType: 'Glass Waste',
          weight: 2100,
          sellerName: 'Vishal Shinde',
          companyName: 'Glass Recovery Co.',
          sellerLocation: 'Kolhapur',
          contactPhone: '9812347896',
          status: 'pending',
        ),
        Order(
          wasteType: 'Plastic Waste',
          weight: 2900,
          sellerName: 'Meera Kulkarni',
          companyName: 'EcoPlastic Industries',
          sellerLocation: 'Aurangabad',
          contactPhone: '9887654320',
          status: 'pending',
        ),
        Order(
          wasteType: 'Metal Waste',
          weight: 3400,
          sellerName: 'Sagar Chavan',
          companyName: 'Metal Processing Co',
          sellerLocation: 'Nagpur',
          contactPhone: '9754312689',
          status: 'pending',
        ),
        Order(
          wasteType: 'Paper Waste',
          weight: 1700,
          sellerName: 'Pooja Sawant',
          companyName: 'Green Paper Mills',
          sellerLocation: 'Satara',
          contactPhone: '9834567123',
          status: 'pending',
        ),
        Order(
          wasteType: 'E-Waste',
          weight: 2300,
          sellerName: 'Nikhil Pawar',
          companyName: 'Tech Waste Solutions',
          sellerLocation: 'Pune',
          contactPhone: '9845612378',
          status: 'pending',
        ),
        Order(
          wasteType: 'Plastic Waste',
          weight: 1500,
          sellerName: 'Tanvi Joshi',
          companyName: 'EcoFriendly Plastics',
          sellerLocation: 'Mumbai',
          contactPhone: '9867541230',
          status: 'pending',
        ),
      ];
      await _save();
    }
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = json.encode(state.map((e) => e.toJson()).toList());
    await _prefs!.setString('orders', encoded);
  }

  void addOrder(Order order) {
    state = [...state, order];
    _save();
  }

  void updateOrderStatus(int index, String status) {
    final copy = [...state];
    if (index < 0 || index >= copy.length) return;
    final oldOrder = copy[index];
    copy[index] = Order(
      wasteType: oldOrder.wasteType,
      weight: oldOrder.weight,
      sellerName: oldOrder.sellerName,
      companyName: oldOrder.companyName,
      sellerLocation: oldOrder.sellerLocation,
      status: status,
      pickupLocation: oldOrder.pickupLocation,
      pickupDate: oldOrder.pickupDate,
      pickupTime: oldOrder.pickupTime,
      progressStatus: oldOrder.progressStatus,
      contactPhone: oldOrder.contactPhone,
    );
    state = copy;
    _save();
  }
}

// providers
final listingsProvider =
    StateNotifierProvider<ListingsNotifier, List<WasteListing>>(
        (ref) => ListingsNotifier());

final pickupRequestsProvider =
    StateNotifierProvider<PickupRequestsNotifier, List<PickupRequest>>(
        (ref) => PickupRequestsNotifier());

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>(
    (ref) => OrdersNotifier());
