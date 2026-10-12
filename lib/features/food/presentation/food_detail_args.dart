import '../domain/recipe.dart';
class FoodDetailArgs {
  const FoodDetailArgs(this.recipe, this.heroTag);
  final Recipe recipe;
  final String heroTag;
}
