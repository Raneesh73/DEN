import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'map_provider.dart';

final authServiceProvider = Provider((ref) => FirebaseAuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).streamUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (e, _) => Stream.value(null),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;
  final Ref _ref;

  AuthController(this._authService, this._firestoreService, this._ref) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signIn(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUp(String email, String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.signUp(email, password);
      if (credential?.user != null) {
        final user = UserModel(
          uid: credential!.user!.uid,
          username: username,
          email: email,
          joinedDenIds: [],
          status: 'online',
        );
        await _firestoreService.createUser(user);
      }
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    _ref.read(mapControllerProvider.notifier).stopTracking();
    await _authService.signOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
    ref,
  );
});
