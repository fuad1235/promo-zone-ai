import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/app_models.dart';
import '../../../common/services/repository_providers.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).signIn(email, password);
    });
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).register(email, password);
    });
  }

  Future<void> completeOnboarding({
    required UserRole role,
    required String displayName,
    String? phone,
    String? bio,
    List<String> niches = const [],
    String? companyName,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = AsyncError(
        StateError('User not authenticated'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).completeOnboarding(
            uid: user.uid,
            email: user.email,
            role: role,
            displayName: displayName,
            phone: phone,
            bio: bio,
            niches: niches,
            companyName: companyName,
          );
    });
  }

  Future<void> chooseRole(UserRole role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).chooseRole(role);
    });
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}
