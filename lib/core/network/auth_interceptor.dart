import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/user_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.userStorage, this.onUnauthorized);
  final UserStorage userStorage;
  final VoidCallback onUnauthorized;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await userStorage.readToken();

    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isLogin = err.requestOptions.path.contains('/auth/login');
    if (err.response?.statusCode == 401 && !isLogin) onUnauthorized();
    handler.next(err);
  }
}