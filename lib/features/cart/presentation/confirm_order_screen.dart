import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/yellow_page.dart';
import 'cart_screen.dart';
import 'providers/cart_providers.dart';

class ConfirmOrderScreen extends ConsumerStatefulWidget {
  const ConfirmOrderScreen({super.key});

  @override
  ConsumerState<ConfirmOrderScreen> createState() =>
      _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends ConsumerState<ConfirmOrderScreen> {
  bool _placing = false;

  Future<void> _placeOrder() async {
    if (_placing) return; 
    setState(() => _placing = true);

    final total = ref.read(cartTotalsProvider).total;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.orange, size: 56),
        title: const Text('Order placed!'),
        content: Text(
          'Thank you. Your order of ${formatMoney(total)} is on its way.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    ref.read(cartControllerProvider.notifier).clear();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartControllerProvider);
    final totals = ref.watch(cartTotalsProvider);
    final textTheme = Theme.of(context).textTheme;

    return YellowPage(
      title: 'Confirm Order',
      showBack: true,
      child: items.isEmpty
          ? EmptyView(
              icon: Icons.shopping_cart_outlined,
              title: 'Nothing to order',
              message: 'Your cart is empty.',
              actionLabel: 'Browse menu',
              onAction: () => context.go(AppRoutes.menu),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    children: [
                      Text(
                        'Order summary',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.quantity}×',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                formatMoney(item.lineTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delivery_dining,
                                color: AppColors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Estimated delivery: 25-35 min',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                CartSummary(
                  totals: totals,
                  buttonLabel: 'Place Order',
                  onPressed: _placing ? null : _placeOrder,
                ),
              ],
            ),
    );
  }
}
