import 'cart_item.dart';

class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.tax,
    required this.fees,
    required this.delivery,
  });

  static const double taxRate = 0.08;
  static const double serviceFee = 1.50;
  static const double deliveryFee = 2.99;

  final double subtotal;
  final double tax;
  final double fees;
  final double delivery;

  double get total => subtotal + tax + fees + delivery;

  factory CartTotals.fromItems(List<CartItem> items) {
    if (items.isEmpty) {
      return const CartTotals(subtotal: 0, tax: 0, fees: 0, delivery: 0);
    }
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    return CartTotals(
      subtotal: subtotal,
      tax: subtotal * taxRate,
      fees: serviceFee,
      delivery: deliveryFee,
    );
  }
}
