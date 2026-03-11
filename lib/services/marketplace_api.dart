// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../models/waste_item.dart';
//
// class MarketplaceApi {
//   /// Replace this URL with your real endpoint
//   static const _endpoint = 'https://example.com/api/marketplace/items';
//
//   static Future<List<WasteItem>> fetchItems() async {
//     final uri = Uri.parse(_endpoint);
//     final resp = await http.get(uri);
//
//     if (resp.statusCode != 200) {
//       throw Exception('Failed to load marketplace items (${resp.statusCode})');
//     }
//
//     final List<dynamic> data = json.decode(resp.body);
//     return data
//         .map((e) => WasteItem.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }
// }
