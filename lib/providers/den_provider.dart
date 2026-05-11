import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final denInviteCodeProvider = FutureProvider.family<String?, String>((ref, denId) {
  return ref.watch(firestoreServiceProvider).getDenInviteCode(denId);
});

class DenController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  DenController(this._firestoreService, this._ref) : super(const AsyncValue.data(null));

  Future<void> createDen(String name) async {
    if (name.trim().isEmpty) {
      state = AsyncValue.error('Please enter a den name', StackTrace.current);
      return;
    }

    final user = _ref.read(userProfileProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.createDen(name, user.uid);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> joinDen(String inviteCode) async {
    if (inviteCode.trim().isEmpty) {
      state = AsyncValue.error('Please enter an invite code', StackTrace.current);
      return;
    }

    final user = _ref.read(userProfileProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final success = await _firestoreService.joinDen(inviteCode, user.uid);
      if (!success) {
        state = AsyncValue.error('Invalid invite code', StackTrace.current);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final denControllerProvider = StateNotifierProvider<DenController, AsyncValue<void>>((ref) {
  return DenController(ref.watch(firestoreServiceProvider), ref);
});


