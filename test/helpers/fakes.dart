import 'package:bictree_assessment/features/auth/domain/auth_repository.dart';
import 'package:bictree_assessment/features/auth/domain/user.dart';
import 'package:bictree_assessment/features/cart/domain/cart_item.dart';
import 'package:bictree_assessment/features/cart/domain/cart_repository.dart';
import 'package:bictree_assessment/features/food/data/recipe_cache.dart';
import 'package:bictree_assessment/features/food/domain/recipe.dart';
import 'package:bictree_assessment/features/food/domain/recipe_repository.dart';

Recipe fakeRecipe(
  int id, {
  double price = 10,
  String name = 'Dish',
  List<String> mealTypes = const ['Dinner'],
  List<String> tags = const [],
  double rating = 4.5,
}) {
  return Recipe(
    id: id,
    name: '$name $id',
    image: '',
    rating: rating,
    reviewCount: 10,
    price: price,
    prepTimeMinutes: 10,
    cookTimeMinutes: 20,
    servings: 2,
    difficulty: 'Easy',
    caloriesPerServing: 300,
    cuisine: 'Italian',
    mealTypes: mealTypes,
    tags: tags,
    ingredients: const ['Flour'],
    instructions: const ['Cook it.'],
  );
}

class InMemoryCartRepository implements CartRepository {
  InMemoryCartRepository([List<CartItem>? initial]) : items = initial ?? [];

  List<CartItem> items;

  @override
  List<CartItem> load() => List.of(items);

  @override
  Future<void> save(List<CartItem> next) async {
    items = List.of(next);
  }
}

class InMemoryRecipeCache implements RecipeCache {
  RecipePage? saved;

  @override
  Future<void> saveFirstPage(RecipePage page) async => saved = page;

  @override
  RecipePage? readFirstPage() {
    final page = saved;
    if (page == null) return null;
    return RecipePage(items: page.items, total: page.total, fromCache: true);
  }
}

class FakeAuthRepository implements AuthRepository {
  int loginCalls = 0;
  String? lastUsername;

  @override
  Future<User> login(String username, String password) async {
    loginCalls++;
    lastUsername = username;
    return const User(
      id: 1,
      username: 'emilys',
      email: 'emily@example.com',
      firstName: 'Emily',
      lastName: 'Johnson',
      gender: 'female',
      image: '',
      accessToken: 'access',
      refreshToken: 'refresh',
    );
  }

  @override
  Future<User?> savedUser() async => null;

  @override
  Future<void> logout() async {}
}
