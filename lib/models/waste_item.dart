class WasteItem {
  final String type;
  final String quantity;
  final double price;
  final double rating;
  final String distance;
  final String seller;
  final bool verified;

  WasteItem({
    required this.type,
    required this.quantity,
    required this.price,
    required this.rating,
    required this.distance,
    required this.seller,
    required this.verified,
  });

  factory WasteItem.fromJson(Map<String, dynamic> json) {
    return WasteItem(
      type: json['type'] as String,
      quantity: json['quantity'] as String,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating'].toString()) ?? 0.0,
      distance: json['distance'] as String,
      seller: json['seller'] as String,
      verified: json['verified'] == true || json['verified'] == 'true',
    );
  }
}
