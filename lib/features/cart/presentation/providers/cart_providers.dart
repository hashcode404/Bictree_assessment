import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../food/domain/recipe.dart';
import '../../data/hive_cart_repository.dart';
import '../../domain/cart_item.dart';
import '../../domain/cart_repository.dart';
import '../../domain/cart_totals.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => HiveCartRepository(Hive.box<String>('cart')),
);

class RemovedCartItem {
  const RemovedCartItem(this.item, this.index);
  final CartItem item;
  final int index;
}

int _clampQuantity(int value) {
  if (value < 1) return 1;
  if (value > kMaxQuantity) return kMaxQuantity;
  return value;
}

class CartController extends Notifier<List<CartItem>> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  List<CartItem> build() => _repo.load();

  void add(Recipe recipe, {int quantity = 1}) {
    final index = state.indexWhere((i) => i.recipeId == recipe.id);
    if (index == -1) {
      _set([
        ...state,
        CartItem(
          recipeId: recipe.id,
          name: recipe.name,
          image: recipe.image,
          price: recipe.price,
          quantity: _clampQuantity(quantity),
        ),
      ]);
    } else {
      _updateQuantity(index, state[index].quantity + quantity);
    }
  }

  void increment(int recipeId) => _changeBy(recipeId, 1);

  void decrement(int recipeId) => _changeBy(recipeId, -1);

  void setQuantity(int recipeId, int quantity) {
    if (quantity <= 0) {
      remove(recipeId);
      return;
    }
    final index = state.indexWhere((i) => i.recipeId == recipeId);
    if (index != -1) _updateQuantity(index, quantity);
  }

  RemovedCartItem? remove(int recipeId) {
    final index = state.indexWhere((i) => i.recipeId == recipeId);
    if (index == -1) return null;
    final removed = RemovedCartItem(state[index], index);
    _set([...state]..removeAt(index));
    return removed;
  }

  void restore(CartItem item, int index) {
    if (state.any((i) => i.recipeId == item.recipeId)) return;
    final next = [...state];
    next.insert(index > next.length ? next.length : index, item);
    _set(next);
  }

  void clear() => _set(const []);

  void _changeBy(int recipeId, int delta) {
    final index = state.indexWhere((i) => i.recipeId == recipeId);
    if (index == -1) return;
    _updateQuantity(index, state[index].quantity + delta);
  }

  void _updateQuantity(int index, int quantity) {
    final next = [...state];
    next[index] = state[index].copyWith(quantity: _clampQuantity(quantity));
    _set(next);
  }

  void _set(List<CartItem> next) {
    state = List.unmodifiable(next);
    unawaited(_repo.save(next).catchError((Object _) {}));
  }
}

final cartControllerProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);

final cartTotalsProvider = Provider<CartTotals>(
  (ref) => CartTotals.fromItems(ref.watch(cartControllerProvider)),
);

final cartCountProvider = Provider<int>((ref) {
  return ref
      .watch(cartControllerProvider)
      .fold<int>(0, (sum, i) => sum + i.quantity);
});
