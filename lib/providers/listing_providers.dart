import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a waste listing created by a seller.
class WasteListing {
  final String wasteType;
  final double weightKg;
  final double pricePerKg;
  final double totalValue;
  final String companyName;
  final String sellerName;
  final String sellerLocation;
  String status; // "available", "pending", "sold"

  WasteListing({
    required this.wasteType,
    required this.weightKg,
    required this.pricePerKg,
    required this.totalValue,
    required this.companyName,
    required this.sellerName,
    required this.sellerLocation,
    this.status = 'available',
  });

  Map<String, dynamic> toJson() => {
        'wasteType': wasteType,
        'weightKg': weightKg,
        'pricePerKg': pricePerKg,
        'totalValue': totalValue,
        'companyName': companyName,
        'sellerName': sellerName,
        'sellerLocation': sellerLocation,
        'status': status,
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
      status: json['status'] as String? ?? 'available',
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
}

/// A simple pickup request generated when a seller chooses a company.
class PickupRequest {
  final String sellerName;
  final String wasteType;
  final double weight;
  final String companyName;
  String status; // pending, accepted, completed

  PickupRequest({
    required this.sellerName,
    required this.wasteType,
    required this.weight,
    required this.companyName,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'sellerName': sellerName,
        'wasteType': wasteType,
        'weight': weight,
        'companyName': companyName,
        'status': status,
      };

  factory PickupRequest.fromJson(Map<String, dynamic> json) {
    return PickupRequest(
      sellerName: json['sellerName'] as String,
      wasteType: json['wasteType'] as String,
      weight: (json['weight'] as num).toDouble(),
      companyName: json['companyName'] as String,
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
  String status; // pending, accepted, completed

  Order({
    required this.wasteType,
    required this.weight,
    required this.sellerName,
    required this.companyName,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'wasteType': wasteType,
        'weight': weight,
        'sellerName': sellerName,
        'companyName': companyName,
        'status': status,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      wasteType: json['wasteType'] as String,
      weight: (json['weight'] as num).toDouble(),
      sellerName: json['sellerName'] as String,
      companyName: json['companyName'] as String,
      status: json['status'] as String? ?? 'pending',
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
