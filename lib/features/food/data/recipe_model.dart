import '../domain/recipe.dart';
double mockPriceFor(int id) => (800 + (id * 379) % 1200) / 100;

class RecipeModel extends Recipe {
  const RecipeModel({
    required super.id,
    required super.name,
    required super.image,
    required super.rating,
    required super.reviewCount,
    required super.price,
    required super.prepTimeMinutes,
    required super.cookTimeMinutes,
    required super.servings,
    required super.difficulty,
    required super.caloriesPerServing,
    required super.cuisine,
    required super.mealTypes,
    required super.tags,
    required super.ingredients,
    required super.instructions,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    return RecipeModel(
      id: id,
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      price: mockPriceFor(id),
      prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt() ?? 0,
      cookTimeMinutes: (json['cookTimeMinutes'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      difficulty: json['difficulty'] as String? ?? '',
      caloriesPerServing: (json['caloriesPerServing'] as num?)?.toInt() ?? 0,
      cuisine: json['cuisine'] as String? ?? '',
      mealTypes: _strings(json['mealType']),
      tags: _strings(json['tags']),
      ingredients: _strings(json['ingredients']),
      instructions: _strings(json['instructions']),
    );
  }
  static Map<String, dynamic> toJson(Recipe r) => {
        'id': r.id,
        'name': r.name,
        'image': r.image,
        'rating': r.rating,
        'reviewCount': r.reviewCount,
        'prepTimeMinutes': r.prepTimeMinutes,
        'cookTimeMinutes': r.cookTimeMinutes,
        'servings': r.servings,
        'difficulty': r.difficulty,
        'caloriesPerServing': r.caloriesPerServing,
        'cuisine': r.cuisine,
        'mealType': r.mealTypes,
        'tags': r.tags,
        'ingredients': r.ingredients,
        'instructions': r.instructions,
      };

  static List<String> _strings(Object? value) =>
      (value as List?)?.map((e) => e.toString()).toList() ?? const [];
}
