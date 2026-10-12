import 'recipe.dart';

class RecipePage {
  const RecipePage({
    required this.items,
    required this.total,
    this.fromCache = false,
  });

  final List<Recipe> items;
  final int total;
  final bool fromCache;
}

abstract class RecipeRepository {
  Future<RecipePage> getRecipes({required int limit, required int skip});

  Future<List<Recipe>> searchRecipes(String query);

  Future<Recipe> getRecipe(int id);
}
