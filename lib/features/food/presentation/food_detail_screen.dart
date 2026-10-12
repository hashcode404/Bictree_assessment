import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/yellow_page.dart';
import '../../cart/domain/cart_item.dart';
import '../../cart/presentation/providers/cart_providers.dart';
import '../domain/recipe.dart';
import 'food_detail_args.dart';
import 'providers/food_providers.dart';
import 'widgets/recipe_widgets.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({super.key, required this.id, this.args});

  final int id;
  final FoodDetailArgs? args;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int _quantity = 1;

  void _addToCart(Recipe recipe) {
    ref.read(cartControllerProvider.notifier).add(recipe, quantity: _quantity);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$_quantity × ${recipe.name} added to cart'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => context.go(AppRoutes.cart),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(recipeDetailProvider(widget.id));
    final recipe = detail.value ?? widget.args?.recipe;

    if (recipe == null) {
      return YellowPage(
        title: 'Details',
        showBack: true,
        child: detail.hasError
            ? ErrorView(
                message: messageOf(detail.error!),
                onRetry: () => ref.invalidate(recipeDetailProvider(widget.id)),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final heroTag =
        widget.args?.heroTag ?? recipeHeroTag('detail', widget.id);
    final top = MediaQuery.paddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightStatusBar,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        bottomNavigationBar: _BottomBar(
          quantity: _quantity,
          total: recipe.price * _quantity,
          onDecrement: () => setState(() => _quantity--),
          onIncrement: () => setState(() => _quantity++),
          canDecrement: _quantity > 1,
          canIncrement: _quantity < kMaxQuantity,
          onAdd: () => _addToCart(recipe),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: Hero(
                      tag: heroTag,
                      child: RecipeImage(url: recipe.image),
                    ),
                  ),
                  Positioned(
                    top: top + 8,
                    left: 16,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: AppColors.orange),
                      ),
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              recipe.name,
                              style: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatMoney(recipe.price),
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          RatingChip(rating: recipe.rating),
                          const SizedBox(width: 8),
                          Text(
                            '(${recipe.reviewCount} reviews)',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${recipe.cuisine} · ${recipe.difficulty}',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _InfoBox(
                            icon: Icons.schedule,
                            value: '${recipe.totalTimeMinutes} min',
                            label: 'Cook time',
                          ),
                          const SizedBox(width: 10),
                          _InfoBox(
                            icon: Icons.people_outline,
                            value: '${recipe.servings}',
                            label: 'Servings',
                          ),
                          const SizedBox(width: 10),
                          _InfoBox(
                            icon: Icons.local_fire_department_outlined,
                            value: '${recipe.caloriesPerServing}',
                            label: 'kcal',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Ingredients',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (final item in recipe.ingredients)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6, right: 10),
                                child: Icon(Icons.circle,
                                    size: 6, color: AppColors.orange),
                              ),
                              Expanded(
                                  child:
                                      Text(item, style: textTheme.bodyMedium)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text('Instructions',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (var i = 0; i < recipe.instructions.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(right: 10),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(recipe.instructions[i],
                                    style: textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.orange, size: 22),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.quantity,
    required this.total,
    required this.onDecrement,
    required this.onIncrement,
    required this.canDecrement,
    required this.canIncrement,
    required this.onAdd,
  });

  final int quantity;
  final double total;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              QuantityStepper(
                quantity: quantity,
                onDecrement: onDecrement,
                onIncrement: onIncrement,
                canDecrement: canDecrement,
                canIncrement: canIncrement,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text('Add to Cart · ${formatMoney(total)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
