import 'package:bictree_assessment/features/cart/domain/cart_item.dart';
import 'package:bictree_assessment/features/cart/domain/cart_totals.dart';
import 'package:bictree_assessment/features/cart/presentation/providers/cart_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemoryCartRepository repo;
  late ProviderContainer container;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [cartRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    repo = InMemoryCartRepository();
    container = makeContainer();
  });

  CartController controller() =>
      container.read(cartControllerProvider.notifier);
  List<CartItem> items() => container.read(cartControllerProvider);

  group('adding', () {
    test('adds a new item', () {
      controller().add(fakeRecipe(1, price: 12.5));
      expect(items(), hasLength(1));
      expect(items().first.recipeId, 1);
      expect(items().first.price, 12.5);
      expect(items().first.quantity, 1);
    });

    test('adding the same dish merges the quantity', () {
      controller().add(fakeRecipe(1), quantity: 2);
      controller().add(fakeRecipe(1), quantity: 3);
      expect(items(), hasLength(1));
      expect(items().first.quantity, 5);
    });

    test('quantity never goes above the maximum', () {
      controller().add(fakeRecipe(1), quantity: 15);
      controller().add(fakeRecipe(1), quantity: 15);
      expect(items().first.quantity, kMaxQuantity);
    });
  });

  group('changing quantity', () {
    test('increment and decrement', () {
      controller().add(fakeRecipe(1));
      controller().increment(1);
      expect(items().first.quantity, 2);
      controller().decrement(1);
      expect(items().first.quantity, 1);
    });

    test('decrement never goes below 1', () {
      controller().add(fakeRecipe(1));
      controller().decrement(1);
      expect(items().first.quantity, 1);
    });

    test('setQuantity to 0 removes the item', () {
      controller().add(fakeRecipe(1));
      controller().setQuantity(1, 0);
      expect(items(), isEmpty);
    });
  });

  group('removing and undo', () {
    test('remove returns the item and its index; restore puts it back', () {
      controller().add(fakeRecipe(1));
      controller().add(fakeRecipe(2));
      controller().add(fakeRecipe(3));

      final removed = controller().remove(2)!;
      expect(items().map((i) => i.recipeId), [1, 3]);
      expect(removed.index, 1);

      controller().restore(removed.item, removed.index);
      expect(items().map((i) => i.recipeId), [1, 2, 3]);
    });

    test('removing an unknown id does nothing', () {
      controller().add(fakeRecipe(1));
      expect(controller().remove(99), isNull);
      expect(items(), hasLength(1));
    });

    test('restore ignores an item that is already in the cart', () {
      controller().add(fakeRecipe(1));
      controller().restore(items().first, 0);
      expect(items(), hasLength(1));
    });

    test('clear empties the cart', () {
      controller().add(fakeRecipe(1));
      controller().add(fakeRecipe(2));
      controller().clear();
      expect(items(), isEmpty);
    });
  });

  group('totals', () {
    test('subtotal, tax, fees, delivery and total', () {
      controller().add(fakeRecipe(1, price: 10), quantity: 2); 
      controller().add(fakeRecipe(2, price: 5)); 

      final totals = container.read(cartTotalsProvider);
      expect(totals.subtotal, closeTo(25, 0.001));
      expect(totals.tax, closeTo(25 * CartTotals.taxRate, 0.001));
      expect(totals.fees, CartTotals.serviceFee);
      expect(totals.delivery, CartTotals.deliveryFee);
      expect(
        totals.total,
        closeTo(25 + 25 * CartTotals.taxRate + 1.50 + 2.99, 0.001),
      );
    });

    test('an empty cart costs nothing, not even delivery', () {
      final totals = container.read(cartTotalsProvider);
      expect(totals.total, 0);
    });

    test('the badge count is the sum of quantities', () {
      controller().add(fakeRecipe(1), quantity: 2);
      controller().add(fakeRecipe(2), quantity: 3);
      expect(container.read(cartCountProvider), 5);
    });
  });

  group('persistence', () {
    test('every change is saved to the repository', () {
      controller().add(fakeRecipe(1), quantity: 2);
      expect(repo.items, hasLength(1));
      expect(repo.items.first.quantity, 2);
    });

    test('a new container (app restart) starts from the saved cart', () {
      controller().add(fakeRecipe(1), quantity: 4);

      final restarted = makeContainer();
      final restored = restarted.read(cartControllerProvider);
      expect(restored, hasLength(1));
      expect(restored.first.recipeId, 1);
      expect(restored.first.quantity, 4);
    });
  });
}
