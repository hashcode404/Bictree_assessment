import 'recipe.dart';
enum FoodCategory {
  snacks('Snacks'),
  meal('Meal'),
  vegan('Vegan'),
  dessert('Dessert'),
  drinks('Drinks');

  const FoodCategory(this.label);
  final String label;

  static const _snackMeals = {'snack', 'appetizer', 'side dish'};
  static const _mainMeals = {'breakfast', 'lunch', 'dinner'};
  static const _veganTags = {'vegan', 'vegetarian'};
  static const _drinkMeals = {'beverage', 'drink'};
  static const _drinkTags = {
    'smoothie',
    'lassi',
    'cocktail',
    'mojito',
    'caipirinha',
  };

  bool matches(Recipe recipe) {
    final meals = recipe.mealTypes.map((e) => e.toLowerCase()).toSet();
    final tags = recipe.tags.map((e) => e.toLowerCase()).toSet();
    switch (this) {
      case FoodCategory.snacks:
        return meals.any(_snackMeals.contains);
      case FoodCategory.meal:
        return meals.any(_mainMeals.contains);
      case FoodCategory.vegan:
        return tags.any(_veganTags.contains);
      case FoodCategory.dessert:
        return meals.contains('dessert');
      case FoodCategory.drinks:
        return meals.any(_drinkMeals.contains) || tags.any(_drinkTags.contains);
    }
  }
}
