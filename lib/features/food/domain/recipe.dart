class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.caloriesPerServing,
    required this.cuisine,
    required this.mealTypes,
    required this.tags,
    required this.ingredients,
    required this.instructions,
  });

  final int id;
  final String name;
  final String image;
  final double rating;
  final int reviewCount;
  final double price;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final String difficulty;
  final int caloriesPerServing;
  final String cuisine;
  final List<String> mealTypes;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> instructions;

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;
}
