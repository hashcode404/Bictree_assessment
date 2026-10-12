import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserStorage {
  UserStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _key = 'user';

  String? _cachedToken; 

  Future<String?> readUserJson() async {
    try {
      return await _storage.read(key: _key);
    } catch (e) {
      debugPrint('UserStorage.readUserJson failed: $e');
      return null;
    }
  }

  Future<void> writeUserJson(String json) async {
    _cachedToken = null;
    await _storage.write(key: _key, value: json);
  }

  Future<String?> readToken() async {
    if (_cachedToken != null) return _cachedToken;
    final raw = await readUserJson();
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final token = map['accessToken'] as String?;
      _cachedToken = (token == null || token.isEmpty) ? null : token;
    } catch (_) {
      return null; 
    }
    return _cachedToken;
  }

  Future<void> clear() async {
    _cachedToken = null;
    try {
      await _storage.delete(key: _key);
    } catch (e) {
      debugPrint('UserStorage.clear failed: $e');
    }
  }
}

final userStorageProvider = Provider<UserStorage>(
  (ref) => UserStorage(const FlutterSecureStorage()),
);
