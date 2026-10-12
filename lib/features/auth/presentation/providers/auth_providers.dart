import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/user_storage.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user.dart';

const kSplashMinDuration = Duration(milliseconds: 1500);

final splashMinDurationProvider = Provider<Duration>((ref) => kSplashMinDuration);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(userStorageProvider),
  ),
);

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;
  final User? user;
  final bool isLoading; 
  final String? error; 
}

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthState();
  }

  Future<void> _restore() async {
    final minSplash = Future<void>.delayed(ref.read(splashMinDurationProvider));
    final user = await _repo.savedUser();
    await minSplash;
    state = user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> login(String username, String password) async {
    state = const AuthState(status: AuthStatus.unauthenticated, isLoading: true);
    try {
      final user = await _repo.login(username, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    }
  }

  void clearError() {
    if (state.error == null) return;
    state = AuthState(status: state.status, user: state.user);
  }

  Future<void> logout() async {
    if (state.status == AuthStatus.unauthenticated && state.user == null) return;
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
