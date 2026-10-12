import 'user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);

  Future<User?> savedUser();

  Future<void> logout();
}
