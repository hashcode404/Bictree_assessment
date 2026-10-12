import 'dart:convert';

import 'package:hive/hive.dart';

import '../domain/cart_item.dart';
import '../domain/cart_repository.dart';
import 'cart_item_model.dart';

class HiveCartRepository implements CartRepository {
  HiveCartRepository(this._box);
  final Box<String> _box;

  static const _key = 'items';

  @override
  List<CartItem> load() {
    final raw = _box.get(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; 
    }
  }

  @override
  Future<void> save(List<CartItem> items) {
    return _box.put(
      _key,
      jsonEncode(items.map(CartItemModel.toJson).toList()),
    );
  }
}
