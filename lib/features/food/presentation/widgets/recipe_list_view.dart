import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/recipe.dart';
import 'recipe_widgets.dart';
class RecipeListView extends ConsumerWidget {
  const RecipeListView({
    super.key,
    required this.items,
    required this.heroSource,
    required this.onRefresh,
    this.onLoadMore,
    this.footer,
    this.emptyTitle = 'No dishes found',
    this.emptyMessage = 'Try another category or search.',
  });

  final List<Recipe> items;
  final String heroSource;
  final Future<void> Function() onRefresh;
  final VoidCallback? onLoadMore;
  final Widget? footer;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (onLoadMore != null &&
            n.metrics.axis == Axis.vertical &&
            n.metrics.extentAfter < 300) {
          onLoadMore!();
        }
        return false;
      },
      child: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: onRefresh,
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 320,
                    child: EmptyView(title: emptyTitle, message: emptyMessage),
                  ),
                  if (footer != null) footer!,
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == items.length) return footer ?? const SizedBox.shrink();
                  final recipe = items[i];
                  return RecipeTile(
                    recipe: recipe,
                    heroTag: recipeHeroTag(heroSource, recipe.id),
                    onTap: () => openFood(context, recipe, heroSource),
                    onAdd: () => addToCart(context, ref, recipe),
                  );
                },
              ),
      ),
    );
  }
}
