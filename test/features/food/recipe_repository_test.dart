import 'dart:convert';
import 'dart:typed_data';

import 'package:bictree_assessment/core/error/failure.dart';
import 'package:bictree_assessment/features/food/data/recipe_model.dart';
import 'package:bictree_assessment/features/food/data/recipe_repository_impl.dart';
import 'package:bictree_assessment/features/food/domain/food_category.dart';
import 'package:bictree_assessment/features/food/domain/recipe_filter.dart';
import 'package:bictree_assessment/features/food/domain/recipe_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);
  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _recipeJson(int id) => {
      'id': id,
      'name': 'Recipe $id',
      'ingredients': ['A', 'B'],
      'instructions': ['Do it'],
      'prepTimeMinutes': 10,
      'cookTimeMinutes': 20,
      'servings': 2,
      'difficulty': 'Easy',
      'cuisine': 'Italian',
      'caloriesPerServing': 300,
      'tags': ['Pizza'],
      'image': 'https://example.com/$id.webp',
      'rating': 4.6,
      'reviewCount': 98,
      'mealType': ['Dinner'],
    };

RecipeRepositoryImpl _repo(
  InMemoryRecipeCache cache,
  Future<ResponseBody> Function(RequestOptions) handler,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..httpClientAdapter = _FakeAdapter(handler);
  return RecipeRepositoryImpl(dio, cache);
}

RecipePage _savedPage() => RecipePage(items: [fakeRecipe(1)], total: 1);

DioException _offline(RequestOptions o) =>
    DioException(requestOptions: o, type: DioExceptionType.connectionError);

void main() {
  group('RecipeRepositoryImpl.getRecipes', () {
    test('parses a page, adds a mock price and saves the first page', () async {
      final cache = InMemoryRecipeCache();
      final repo = _repo(cache, (o) async {
        expect(o.path, '/recipes');
        expect(o.queryParameters['limit'], 20);
        expect(o.queryParameters['skip'], 0);
        return _json({
          'recipes': [_recipeJson(1), _recipeJson(2)],
          'total': 50,
          'skip': 0,
          'limit': 20,
        });
      });

      final page = await repo.getRecipes(limit: 20, skip: 0);

      expect(page.items, hasLength(2));
      expect(page.total, 50);
      expect(page.fromCache, isFalse);
      expect(page.items.first.name, 'Recipe 1');
      expect(page.items.first.price, mockPriceFor(1));
      expect(cache.saved, isNotNull);
    });

    test('offline: returns the saved first page', () async {
      final cache = InMemoryRecipeCache()
        ..saved = _savedPage();
      final repo = _repo(cache, (o) async => throw _offline(o));

      final page = await repo.getRecipes(limit: 20, skip: 0);

      expect(page.fromCache, isTrue);
      expect(page.items, hasLength(1));
    });

    test('offline with nothing saved: throws NetworkFailure', () async {
      final repo = _repo(InMemoryRecipeCache(), (o) async => throw _offline(o));

      expect(
        repo.getRecipes(limit: 20, skip: 0),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('offline on a later page does not use the cache', () async {
      final cache = InMemoryRecipeCache()
        ..saved = _savedPage();
      final repo = _repo(cache, (o) async => throw _offline(o));

      expect(
        repo.getRecipes(limit: 20, skip: 20),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('a 401 becomes UnauthorizedFailure', () async {
      final repo = _repo(
        InMemoryRecipeCache(),
        (o) async => _json({'message': 'Token expired'}, status: 401),
      );

      expect(
        repo.getRecipes(limit: 20, skip: 0),
        throwsA(isA<UnauthorizedFailure>()),
      );
    });

    test('a server error becomes ServerFailure with the API message', () async {
      final repo = _repo(
        InMemoryRecipeCache(),
        (o) async => _json({'message': 'Boom'}, status: 500),
      );

      await expectLater(
        repo.getRecipes(limit: 20, skip: 0),
        throwsA(
          isA<ServerFailure>().having((f) => f.message, 'message', 'Boom'),
        ),
      );
    });

    test('a malformed body becomes UnknownFailure, not a raw exception',
        () async {
      final repo = _repo(
        InMemoryRecipeCache(),
        (o) async => _json({'unexpected': true}),
      );

      expect(
        repo.getRecipes(limit: 20, skip: 0),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('search and detail', () {
    test('searchRecipes sends the query', () async {
      final repo = _repo(InMemoryRecipeCache(), (o) async {
        expect(o.path, '/recipes/search');
        expect(o.queryParameters['q'], 'pizza');
        return _json({
          'recipes': [_recipeJson(1)],
          'total': 1,
        });
      });

      final results = await repo.searchRecipes('pizza');
      expect(results.single.id, 1);
    });

    test('getRecipe loads one recipe by id', () async {
      final repo = _repo(InMemoryRecipeCache(), (o) async {
        expect(o.path, '/recipes/7');
        return _json(_recipeJson(7));
      });

      final recipe = await repo.getRecipe(7);
      expect(recipe.id, 7);
      expect(recipe.price, mockPriceFor(7));
    });
  });

  group('mock price', () {
    test('is stable and inside the slider range for every id', () {
      for (var id = 1; id <= 50; id++) {
        final price = mockPriceFor(id);
        expect(price, mockPriceFor(id));
        expect(price, inInclusiveRange(kPriceMin, kPriceMax));
      }
    });
  });

  group('filtering', () {
    final items = [
      fakeRecipe(1, price: 9, mealTypes: ['Dessert'], rating: 4.0),
      fakeRecipe(2, price: 15, mealTypes: ['Dinner'], tags: ['Vegetarian'], rating: 4.9),
      fakeRecipe(3, price: 12, mealTypes: ['Snack'], tags: ['Smoothie'], rating: 4.5),
    ];

    test('category filter uses mealType and tags', () {
      final dessert = applyFilter(
        items,
        const RecipeFilter(category: FoodCategory.dessert),
      );
      expect(dessert.map((r) => r.id), [1]);

      final vegan = applyFilter(
        items,
        const RecipeFilter(category: FoodCategory.vegan),
      );
      expect(vegan.map((r) => r.id), [2]);

      final drinks = applyFilter(
        items,
        const RecipeFilter(category: FoodCategory.drinks),
      );
      expect(drinks.map((r) => r.id), [3]);
    });

    test('price range removes items outside it', () {
      final result = applyFilter(
        items,
        const RecipeFilter(minPrice: 10, maxPrice: 14),
      );
      expect(result.map((r) => r.id), [3]);
    });

    test('rating sort puts the best first', () {
      final result = applyFilter(
        items,
        const RecipeFilter(sort: SortOption.ratingHigh),
      );
      expect(result.map((r) => r.id), [2, 3, 1]);
    });

    test('price sort works both ways', () {
      expect(
        applyFilter(items, const RecipeFilter(sort: SortOption.priceLow))
            .map((r) => r.id),
        [1, 3, 2],
      );
      expect(
        applyFilter(items, const RecipeFilter(sort: SortOption.priceHigh))
            .map((r) => r.id),
        [2, 3, 1],
      );
    });
  });
}
