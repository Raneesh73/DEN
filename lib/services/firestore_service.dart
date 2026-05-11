import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/den_model.dart';
import '../models/message_model.dart';
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

  Future<void> updateUserStatus(String uid, String status) async {
    await _db.collection('users').doc(uid).update({'status': status});
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
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
      final userDoc = await _db.collection('users').doc(ownerId).get();
      final user = UserModel.fromMap(userDoc.data()!);
      
      if (user.joinedDenIds.length >= 3) {
        throw Exception('Maximum limit of 3 Dens reached.');
      }

      final denId = _db.collection('dens').doc().id;
      final inviteCode = _generateInviteCode();
      
      final den = DenModel(
        denId: denId,
        denName: denName,
        inviteCode: inviteCode,
        ownerId: ownerId,
        members: [ownerId],
        createdAt: DateTime.now(),
      );

      await _db.collection('dens').doc(denId).set(den.toMap());
      await _db.collection('users').doc(ownerId).update({
        'activeDenId': denId,
        'joinedDenIds': FieldValue.arrayUnion([denId]),
      });
      
      return denId;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> joinDen(String inviteCode, String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final user = UserModel.fromMap(userDoc.data()!);
      
      if (user.joinedDenIds.length >= 3) {
        throw Exception('Maximum limit of 3 Dens reached.');
      }

      final query = await _db.collection('dens')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase().trim())
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return false;

      final denDoc = query.docs.first;
      final denId = denDoc.id;

      if (user.joinedDenIds.contains(denId)) {
        throw Exception('You are already a member of this Den.');
      }

      await _db.collection('dens').doc(denId).update({
        'members': FieldValue.arrayUnion([uid])
      });
      
      await _db.collection('users').doc(uid).update({
        'activeDenId': denId,
        'joinedDenIds': FieldValue.arrayUnion([denId]),
      });
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> switchActiveDen(String uid, String denId) async {
    await _db.collection('users').doc(uid).update({'activeDenId': denId});
  }

  Future<void> leaveDen(String uid, String denId) async {
    await _db.collection('dens').doc(denId).update({
      'members': FieldValue.arrayRemove([uid])
    });
    
    final userDoc = await _db.collection('users').doc(uid).get();
    final user = UserModel.fromMap(userDoc.data()!);
    
    List<String> updatedDens = List.from(user.joinedDenIds)..remove(denId);
    String? nextActiveDen = updatedDens.isNotEmpty ? updatedDens.first : null;

    await _db.collection('users').doc(uid).update({
      'activeDenId': nextActiveDen,
      'joinedDenIds': updatedDens,
    });
  }

  Future<void> deleteDen(String denId) async {
    final denDoc = await _db.collection('dens').doc(denId).get();
    if (!denDoc.exists) return;
    
    final den = DenModel.fromMap(denDoc.data()!);
    
    // Update all members
    for (String memberId in den.members) {
      final mDoc = await _db.collection('users').doc(memberId).get();
      if (mDoc.exists) {
        final m = UserModel.fromMap(mDoc.data()!);
        List<String> updatedDens = List.from(m.joinedDenIds)..remove(denId);
        String? nextActiveDen = updatedDens.isNotEmpty ? updatedDens.first : null;
        await _db.collection('users').doc(memberId).update({
          'activeDenId': nextActiveDen,
          'joinedDenIds': updatedDens,
        });
      }
    }
    
    await _db.collection('dens').doc(denId).delete();
  }

  Stream<List<UserModel>> streamDenMembers(String denId) {
    return _db.collection('users').where('activeDenId', isEqualTo: denId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Stream<List<DenModel>> streamUserDens(List<String> denIds) {
    if (denIds.isEmpty) return Stream.value([]);
    return _db.collection('dens').where(FieldPath.documentId, whereIn: denIds).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DenModel.fromMap(doc.data())).toList();
    });
  }

  // Quick Message Operations
  Future<void> sendQuickMessage(String senderId, String senderName, String denId, String content) async {
    final messageId = _db.collection('messages').doc().id;
    final message = MessageModel(
      messageId: messageId,
      senderId: senderId,
      senderName: senderName,
      denId: denId,
      content: content,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(seconds: 15)),
    );
    await _db.collection('messages').doc(messageId).set(message.toMap());
  }

  Stream<List<MessageModel>> streamQuickMessages(String denId) {
    return _db.collection('messages')
        .where('denId', isEqualTo: denId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList());
  }

  // SOS & Alerts
  Future<void> sendSOSAlert(String uid, String name, double lat, double lng, String denId) async {
    await _db.collection('alerts').add({
      'senderId': uid,
      'senderName': name,
      'latitude': lat,
      'longitude': lng,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'SOS',
      'denId': denId,
    });
    
    await _db.collection('users').doc(uid).update({'status': 'sos'});
    await _db.collection('dens').doc(denId).update({'sosActive': true});
  }

  Stream<List<Map<String, dynamic>>> streamSOSAlerts(String denId) {
    return _db.collection('alerts')
        .where('denId', isEqualTo: denId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }
}
