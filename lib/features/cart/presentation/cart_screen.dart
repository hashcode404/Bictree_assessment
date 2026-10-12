import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/yellow_page.dart';
import '../../food/presentation/widgets/recipe_widgets.dart';
import '../domain/cart_item.dart';
import '../domain/cart_totals.dart';
import 'providers/cart_providers.dart';

void removeWithUndo(BuildContext context, WidgetRef ref, CartItem item) {
  final controller = ref.read(cartControllerProvider.notifier);
  final removed = controller.remove(item.recipeId);
  if (removed == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${item.name} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.restore(removed.item, removed.index),
        ),
      ),
    );
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartControllerProvider);
    final totals = ref.watch(cartTotalsProvider);

    return YellowPage(
      title: 'Cart',
      child: items.isEmpty
          ? EmptyView(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add something tasty from the menu.',
              actionLabel: 'Browse menu',
              onAction: () => context.go(AppRoutes.menu),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _CartTile(item: items[i]),
                  ),
                ),
                CartSummary(
                  totals: totals,
                  buttonLabel: 'Checkout',
                  onPressed: () => context.push(AppRoutes.confirm),
                ),
              ],
            ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cartControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey('cart-${item.recipeId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => removeWithUndo(context, ref, item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 68,
                height: 68,
                child: RecipeImage(url: item.image),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(item.lineTotal),
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            QuantityStepper(
              quantity: item.quantity,
              canIncrement: item.quantity < kMaxQuantity,
              onIncrement: () => controller.increment(item.recipeId),
              onDecrement: () {
                if (item.quantity > 1) {
                  controller.decrement(item.recipeId);
                } else {
                  removeWithUndo(context, ref, item);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CartSummary extends StatelessWidget {
  const CartSummary({
    super.key,
    required this.totals,
    required this.buttonLabel,
    required this.onPressed,
  });

  final CartTotals totals;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('Subtotal', totals.subtotal),
          _row('Tax (${(CartTotals.taxRate * 100).round()}%)', totals.tax),
          _row('Fees', totals.fees),
          _row('Delivery', totals.delivery),
          const Divider(height: 20),
          _row('Total', totals.total, bold: true),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 13,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.orange : AppColors.text,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatMoney(value), style: style),
        ],
      ),
    );
  }
}
