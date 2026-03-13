import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class Listing {
  final String id;
  final String title;
  final String description;
  final String category;
  final String quantity;
  final double price;
  final String sellerId;
  final DateTime createdAt;
  final String status;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.quantity,
    required this.price,
    required this.sellerId,
    required this.createdAt,
    this.status = 'active',
  });

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Listing(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      sellerId: data['sellerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'quantity': quantity,
      'price': price,
      'sellerId': sellerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}

final userListingsProvider = StreamProvider<List<Listing>>((ref) {
  final user = ref.watch(authProvider);
  if (user.email == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('listings')
      .where(
        'sellerId',
        isEqualTo: user.email,
      ) // Using email as ID based on auth_provider
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList(),
      );
});
