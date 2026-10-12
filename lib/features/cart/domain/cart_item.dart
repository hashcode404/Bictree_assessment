const int kMaxQuantity = 20;

class CartItem {
  const CartItem({
    required this.recipeId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  final int recipeId;
  final String name;
  final String image;
  final double price;
  final int quantity;

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        recipeId: recipeId,
        name: name,
        image: image,
        price: price,
        quantity: quantity ?? this.quantity,
      );
}
