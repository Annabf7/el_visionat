import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Seeds the `teams` collection from the bundled JSON asset if it's empty.
Future<void> seedTeamsIfEmpty(FirebaseFirestore firestore) async {
  final coll = firestore.collection('teams');
  final snapshot = await coll.limit(1).get();
  if (snapshot.docs.isNotEmpty) return; // already seeded

  final jsonStr = await rootBundle.loadString(
    'assets/data/supercopa_teams.json',
  );
  final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;

  final batch = firestore.batch();
  for (final item in data) {
    final docRef = coll.doc(item['id']);
    final map = Map<String, dynamic>.from(item as Map);
    // Keep only expected fields
    batch.set(docRef, {
      'name': map['name'] ?? '',
      'acronym': map['acronym'] ?? '',
      'gender': map['gender'] ?? '',
      'logoUrl': map['logoUrl'] ?? '',
    });
  }
  await batch.commit();
}
