import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/yellow_page.dart';
import '../domain/recipe_filter.dart';
import 'providers/food_providers.dart';
import 'widgets/filter_widgets.dart';
import 'widgets/recipe_list_view.dart';
import 'widgets/recipe_widgets.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});
  static const _autoFillBelow = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesControllerProvider);
    final filter = ref.watch(menuFilterProvider);
    final controller = ref.read(recipesControllerProvider.notifier);
    final filterController = ref.read(menuFilterProvider.notifier);
    final fromCache = recipes.value?.fromCache ?? false;

    return YellowPage(
      title: 'Menu',
      child: Column(
        children: [
          if (fromCache) OfflineBanner(onRetry: controller.refresh),
          const SizedBox(height: 14),
          CategoryChips(
            selected: filter.category,
            onSelected: filterController.setCategory,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Sort By',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SortDropdown(
                      value: filter.sort,
                      onChanged: filterController.setSort,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: recipes.when(
              loading: () => const RecipeListSkeleton(),
              error: (e, _) => ErrorView(
                message: messageOf(e),
                onRetry: () => ref.invalidate(recipesControllerProvider),
              ),
              data: (state) {
                final visible = applyFilter(state.items, filter);
                if (visible.length < _autoFillBelow &&
                    state.hasMore &&
                    !state.isLoadingMore &&
                    !state.loadMoreFailed) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => controller.loadMore());
                }
                return RecipeListView(
                  items: visible,
                  heroSource: 'menu',
                  onRefresh: controller.refresh,
                  onLoadMore: controller.loadMore,
                  footer: LoadMoreFooter(
                    state: state,
                    onRetry: controller.loadMore,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
