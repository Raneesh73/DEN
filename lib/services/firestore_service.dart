import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/den_model.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User Operations
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUserLocation(String uid, double lat, double lng) async {
    await _db.collection('users').doc(uid).update({
      'latitude': lat,
      'longitude': lng,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // SOS & Alerts
  Future<void> sendSOSAlert(String uid, String name, double lat, double lng) async {
    await _db.collection('alerts').add({
      'senderId': uid,
      'senderName': name,
      'latitude': lat,
      'longitude': lng,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'SOS',
    });
  }

  Stream<List<Map<String, dynamic>>> streamSOSAlerts(String denId) {
    return _db.collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Den Operations
  Future<String?> getDenInviteCode(String denId) async {
    final doc = await _db.collection('dens').doc(denId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['inviteCode'] as String?;
  }

  Future<String> createDen(String denName, String ownerId) async {
    try {
      final denId = _db.collection('dens').doc().id;
      final inviteCode = _generateInviteCode();
      
      final den = DenModel(
        denId: denId,
        denName: denName,
        inviteCode: inviteCode,
        ownerId: ownerId,
        members: [ownerId],
      );

      await _db.collection('dens').doc(denId).set(den.toMap());
      await _db.collection('users').doc(ownerId).update({'denId': denId});
      
      return denId;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> joinDen(String inviteCode, String uid) async {
    try {
      final query = await _db.collection('dens')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase().trim())
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return false;

      final denDoc = query.docs.first;
      final denId = denDoc.id;

      await _db.collection('dens').doc(denId).update({
        'members': FieldValue.arrayUnion([uid])
      });
      
      await _db.collection('users').doc(uid).update({'denId': denId});
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<UserModel>> streamDenMembers(String denId) {
    return _db.collection('users').where('denId', isEqualTo: denId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }
}
