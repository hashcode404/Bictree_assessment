import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/recipe_cache.dart';
import '../../data/recipe_repository_impl.dart';
import '../../domain/food_category.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_filter.dart';
import '../../domain/recipe_repository.dart';

final recipeCacheProvider = Provider<RecipeCache>(
  (ref) => HiveRecipeCache(Hive.box<String>('cache')),
);

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(recipeCacheProvider),
  ),
);

class RecipesState {
  const RecipesState({
    this.items = const [],
    this.total = 0,
    this.fromCache = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Recipe> items;
  final int total;
  final bool fromCache;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore => !fromCache && items.length < total;

  RecipesState copyWith({
    List<Recipe>? items,
    int? total,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return RecipesState(
      items: items ?? this.items,
      total: total ?? this.total,
      fromCache: fromCache,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}
class RecipesController extends AsyncNotifier<RecipesState> {
  static const pageSize = 20;

  RecipeRepository get _repo => ref.read(recipeRepositoryProvider);

  @override
  Future<RecipesState> build() async {
    final page = await _repo.getRecipes(limit: pageSize, skip: 0);
    return RecipesState(
      items: page.items,
      total: page.total,
      fromCache: page.fromCache,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final page = await _repo.getRecipes(
        limit: pageSize,
        skip: current.items.length,
      );
      state = AsyncData(current.copyWith(
        items: [...current.items, ...page.items],
        total: page.total,
        isLoadingMore: false,
      ));
    } on Failure {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
    }
  }
}

final recipesControllerProvider =
    AsyncNotifierProvider<RecipesController, RecipesState>(
  RecipesController.new,
);
final bestSellersProvider = Provider<List<Recipe>>((ref) {
  final items =
      ref.watch(recipesControllerProvider).value?.items ?? const <Recipe>[];
  final sorted = [...items]..sort((a, b) => b.rating.compareTo(a.rating));
  return sorted.take(8).toList();
});

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe, int>((ref, id) {
  return ref.watch(recipeRepositoryProvider).getRecipe(id);
});
final searchResultsProvider =
    FutureProvider.autoDispose.family<List<Recipe>, String>((ref, query) {
  return ref.watch(recipeRepositoryProvider).searchRecipes(query);
});

class FilterController extends Notifier<RecipeFilter> {
  @override
  RecipeFilter build() => const RecipeFilter();

  void setCategory(FoodCategory? category) {
    state = state.copyWith(category: category, clearCategory: category == null);
  }

  void setSort(SortOption sort) => state = state.copyWith(sort: sort);

  void setPriceRange(double min, double max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void reset() => state = const RecipeFilter();
}
final menuFilterProvider =
    NotifierProvider<FilterController, RecipeFilter>(FilterController.new);
