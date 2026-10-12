import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../domain/recipe.dart';
import '../food_detail_args.dart';
import '../providers/food_providers.dart';
String recipeHeroTag(String source, int id) => '$source-recipe-$id';

void openFood(BuildContext context, Recipe recipe, String source) {
  context.push(
    AppRoutes.foodPath(recipe.id),
    extra: FoodDetailArgs(recipe, recipeHeroTag(source, recipe.id)),
  );
}

void addToCart(BuildContext context, WidgetRef ref, Recipe recipe) {
  ref.read(cartControllerProvider.notifier).add(recipe);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${recipe.name} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
}

class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.inputFill,
      child: Center(child: Icon(Icons.fastfood, color: AppColors.orange)),
    );
    if (url.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.inputFill),
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.price});
  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
      ),
      child: Text(
        formatMoney(price),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class RatingChip extends StatelessWidget {
  const RatingChip({super.key, required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF5B301)),
        ],
      ),
    );
  }
}
class RecipeTile extends StatelessWidget {
  const RecipeTile({
    super.key,
    required this.recipe,
    required this.heroTag,
    required this.onTap,
    required this.onAdd,
  });

  final Recipe recipe;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Hero(tag: heroTag, child: RecipeImage(url: recipe.image)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${recipe.cuisine} · ${recipe.difficulty}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFF5B301)),
                        const SizedBox(width: 2),
                        Text(recipe.rating.toStringAsFixed(1),
                            style: textTheme.bodySmall),
                        const SizedBox(width: 10),
                        const Icon(Icons.schedule,
                            size: 13, color: AppColors.orange),
                        const SizedBox(width: 2),
                        Text('${recipe.totalTimeMinutes} min',
                            style: textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(recipe.price),
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  InkWell(
                    onTap: onAdd,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key, required this.state, required this.onRetry});
  final RecipesState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    if (state.isLoadingMore) {
      return const CircularProgressIndicator(color: AppColors.orange);
    }
    if (state.loadMoreFailed) {
      return TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text("Couldn't load more. Tap to retry"),
      );
    }
    if (!state.hasMore && state.items.isNotEmpty) {
      return Text(
        "You're all caught up",
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return const SizedBox.shrink();
  }
}
class RecipeListSkeleton extends StatelessWidget {
  const RecipeListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6E6E6),
      highlightColor: const Color(0xFFF5F5F5),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 104,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
