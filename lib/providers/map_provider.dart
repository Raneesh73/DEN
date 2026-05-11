import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import '../models/user_model.dart';
import '../utils/haversine.dart';

import '../models/message_model.dart';

final locationServiceProvider = Provider((ref) => LocationService());

enum MapPermissionState { initial, granted, denied, permanentlyDenied }

class MapController extends StateNotifier<AsyncValue<MapPermissionState>> {
  final LocationService _locationService;
  final FirestoreService _firestoreService;
  final Ref _ref;
  DateTime? _lastUpdateTime;
  final Set<String> _nearbyNotified = {};
  bool _isDenUnited = false;

  MapController(this._locationService, this._firestoreService, this._ref) 
    : super(const AsyncValue.data(MapPermissionState.initial));

  Future<void> initLocationTracking() async {
    try {
      final hasPermission = await _locationService.handlePermission();
      if (!hasPermission) {
        final status = await Geolocator.checkPermission();
        if (status == LocationPermission.deniedForever) {
          state = const AsyncValue.data(MapPermissionState.permanentlyDenied);
        } else {
          state = const AsyncValue.data(MapPermissionState.denied);
        }
        return;
      }

      state = const AsyncValue.data(MapPermissionState.granted);
    } catch (e) {
      debugPrint("Location initialization error: $e");
      state = const AsyncValue.data(MapPermissionState.denied);
      return;
    }

    _locationService.startLocationTracking((position) {
      final user = _ref.read(userProfileProvider).value;
      if (user != null) {
        final now = DateTime.now();
        // Update every 30 seconds as requested or significant movement
        if (_lastUpdateTime == null || now.difference(_lastUpdateTime!).inSeconds >= 30) {
          _lastUpdateTime = now;
          _firestoreService.updateUserLocation(user.uid, position.latitude, position.longitude);
          _checkProximity(position.latitude, position.longitude);
        }
      }
    });
  }

  void stopTracking() {
    _locationService.stopLocationTracking();
  }

  void _checkProximity(double lat, double lng) {
    final members = _ref.read(denMembersProvider).value ?? [];
    final currentUser = _ref.read(userProfileProvider).value;
    if (currentUser == null) return;

    int nearbyCount = 0;

    for (var member in members) {
      if (member.uid == currentUser.uid) {
        nearbyCount++;
        continue;
      }
      if (member.latitude == null || member.longitude == null) continue;

      final distance = Haversine.calculateDistance(lat, lng, member.latitude!, member.longitude!);
      
      if (distance <= 10) {
        nearbyCount++;
        if (!_nearbyNotified.contains(member.uid)) {
          _nearbyNotified.add(member.uid);
        }
      } else {
        _nearbyNotified.remove(member.uid);
      }
    }

    // DEN UNITED logic with cooldown/trigger once refinement
    if (nearbyCount == members.length && members.length > 1) {
      if (!_isDenUnited) {
        _isDenUnited = true;
        _ref.read(denUnitedProvider.notifier).state = true;
      }
    } else {
      // Only reset when they separate significantly (e.g. 100m) to prevent flickering
      bool anyFar = false;
      for (var member in members) {
        if (member.uid == currentUser.uid || member.latitude == null) continue;
        final d = Haversine.calculateDistance(lat, lng, member.latitude!, member.longitude!);
        if (d > 100) {
          anyFar = true;
          break;
        }
      }
      if (anyFar && _isDenUnited) {
        _isDenUnited = false;
        _ref.read(denUnitedProvider.notifier).state = false;
      }
    }
  }

  Future<void> sendSOS() async {
    final user = _ref.read(userProfileProvider).value;
    if (user == null || user.latitude == null || user.activeDenId == null) return;
    
    await _firestoreService.sendSOSAlert(user.uid, user.username, user.latitude!, user.longitude!, user.activeDenId!);
  }

  Future<void> sendQuickMessage(String content) async {
    final user = _ref.read(userProfileProvider).value;
    if (user == null || user.activeDenId == null) return;
    
    await _firestoreService.sendQuickMessage(user.uid, user.username, user.activeDenId!, content);
  }
}

final denUnitedProvider = StateProvider<bool>((ref) => false);

final mapControllerProvider = StateNotifierProvider<MapController, AsyncValue<MapPermissionState>>((ref) {
  return MapController(
    ref.watch(locationServiceProvider),
    ref.watch(firestoreServiceProvider),
    ref,
  );
});

final denMembersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user?.activeDenId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamDenMembers(user!.activeDenId!);
});

final alertsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user?.activeDenId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamSOSAlerts(user!.activeDenId!);
});

final quickMessagesProvider = StreamProvider<List<MessageModel>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user?.activeDenId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamQuickMessages(user!.activeDenId!);
});
