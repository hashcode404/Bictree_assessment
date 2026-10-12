import 'package:bictree_assessment/core/utils/money.dart';
import 'package:bictree_assessment/features/cart/domain/cart_item.dart';
import 'package:bictree_assessment/features/cart/presentation/cart_screen.dart';
import 'package:bictree_assessment/features/cart/presentation/providers/cart_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

Widget _app(InMemoryCartRepository repo) {
  return ProviderScope(
    overrides: [cartRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: CartScreen()),
  );
}

void main() {
  Future<void> pumpCart(WidgetTester tester, InMemoryCartRepository repo) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state for an empty cart', (tester) async {
    await pumpCart(tester, InMemoryCartRepository());

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Checkout'), findsNothing);
  });

  testWidgets('lists items with totals and updates on quantity change',
      (tester) async {
    final repo = InMemoryCartRepository([
      const CartItem(
        recipeId: 1,
        name: 'Pizza',
        image: '',
        price: 10,
        quantity: 2,
      ),
    ]);
    await pumpCart(tester, repo);

    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text(formatMoney(20)), findsWidgets); 

    await tester.tap(find.byTooltip('Increase'));
    await tester.pump();

    expect(find.text(formatMoney(30)), findsWidgets);
    expect(repo.items.single.quantity, 3);
  });

  testWidgets('decrementing the last unit removes the item and offers Undo',
      (tester) async {
    final repo = InMemoryCartRepository([
      const CartItem(
        recipeId: 1,
        name: 'Pizza',
        image: '',
        price: 10,
        quantity: 1,
      ),
    ]);
    await pumpCart(tester, repo);

    await tester.tap(find.byTooltip('Decrease'));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Pizza'), findsOneWidget);
    expect(repo.items, hasLength(1));
  });
}
