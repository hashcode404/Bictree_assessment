import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/storage/user_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio, this._userStorage);
  final Dio _dio;
  final UserStorage _userStorage;

  @override
  Future<User> login(String username, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password, 'expiresInMins': 60},
      );
      final user = UserModel.fromJson(res.data!);
      if (user.accessToken.isEmpty) {
        throw const ServerFailure('Login failed. Please try again.');
      }
      await _userStorage.writeUserJson(jsonEncode(UserModel.toJson(user)));
      return user;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400 || code == 401) {
        throw const ServerFailure('Incorrect username or password.');
      }
      throw mapDioException(e);
    } on Failure {
      rethrow;
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  @override
  Future<User?> savedUser() async {
    final raw = await _userStorage.readUserJson();
    if (raw == null) return null;
    try {
      final user = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return user.accessToken.isEmpty ? null : user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() => _userStorage.clear();
  

}