import 'cart_item.dart';

abstract class CartRepository {
  List<CartItem> load();

  Future<void> save(List<CartItem> items);
}
