import '../domain/cart_item.dart';

class CartItemModel {
  static CartItem fromJson(Map<String, dynamic> json) => CartItem(
        recipeId: (json['recipeId'] as num).toInt(),
        name: json['name'] as String? ?? '',
        image: json['image'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
      );

  static Map<String, dynamic> toJson(CartItem item) => {
        'recipeId': item.recipeId,
        'name': item.name,
        'image': item.image,
        'price': item.price,
        'quantity': item.quantity,
      };
}
