import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/nearby_company.dart';

enum NearbyCompanyDataSource { firestore }

class NearbyCompanyFeed {
  const NearbyCompanyFeed({
    required this.companies,
    required this.source,
    this.message,
  });

  final List<NearbyCompany> companies;
  final NearbyCompanyDataSource source;
  final String? message;
}

class RealtimeCompanyService {
  RealtimeCompanyService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<NearbyCompanyFeed> watchNearbyCompanies({
    required LatLng center,
    int radiusMeters = 15000,
  }) async* {
    try {
      await for (final snapshot
          in _firestore
              .collection('companies')
              .snapshots(includeMetadataChanges: true)) {
        final liveCompanies = snapshot.docs
            .map((doc) {
              try {
                return NearbyCompany.fromFirestore(
                  id: doc.id,
                  data: doc.data(),
                  userLatitude: center.latitude,
                  userLongitude: center.longitude,
                );
              } on FormatException {
                return null;
              }
            })
            .whereType<NearbyCompany>()
            .where((company) {
              final data = snapshot.docs
                  .firstWhere((doc) => doc.id == company.id)
                  .data();
              final isActive = data['isActive'] != false;
              final isVerified = data['isVerified'] != false;
              return isActive &&
                  isVerified &&
                  company.distanceMeters <= radiusMeters;
            })
            .toList(growable: false);

        liveCompanies.sort(
          (first, second) =>
              first.distanceMeters.compareTo(second.distanceMeters),
        );

        if (liveCompanies.isNotEmpty) {
          yield NearbyCompanyFeed(
            companies: liveCompanies.take(30).toList(growable: false),
            source: NearbyCompanyDataSource.firestore,
            message: 'Showing live company updates from Firestore.',
          );
          continue;
        }

        yield const NearbyCompanyFeed(
          companies: [],
          source: NearbyCompanyDataSource.firestore,
          message: 'No live companies matched this area yet.',
        );
      }
    } on FirebaseException catch (error) {
      final message = error.code == 'permission-denied'
          ? 'Realtime companies are blocked by Firestore rules. Allow reads on the companies collection.'
          : 'Could not connect to the realtime company feed right now.';

      yield NearbyCompanyFeed(
        companies: const [],
        source: NearbyCompanyDataSource.firestore,
        message: message,
      );
    }
  }
}
