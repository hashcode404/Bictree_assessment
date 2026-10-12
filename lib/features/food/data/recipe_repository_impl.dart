import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../domain/recipe.dart';
import '../domain/recipe_repository.dart';
import 'recipe_cache.dart';
import 'recipe_model.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl(this._dio, this._cache);

  final Dio _dio;
  final RecipeCache _cache;

  @override
  Future<RecipePage> getRecipes({required int limit, required int skip}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/recipes',
        queryParameters: {'limit': limit, 'skip': skip},
      );
      final page = _parsePage(res.data!);
      if (skip == 0) {
        try {
          await _cache.saveFirstPage(page);
        } catch (_) {
        }
      }
      return page;
    } on DioException catch (e) {
      final failure = mapDioException(e);
      if (skip == 0 && failure is NetworkFailure) {
        final cached = _cache.readFirstPage();
        if (cached != null) return cached;
      }
      throw failure;
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  @override
  Future<List<Recipe>> searchRecipes(String query) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/recipes/search',
          queryParameters: {'q': query, 'limit': 50},
        );
        return _parsePage(res.data!).items;
      });

  @override
  Future<Recipe> getRecipe(int id) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/recipes/$id');
        return RecipeModel.fromJson(res.data!);
      });

  RecipePage _parsePage(Map<String, dynamic> data) {
    final items = (data['recipes'] as List)
        .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecipePage(items: items, total: (data['total'] as num).toInt());
  }
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (_) {
      throw const UnknownFailure();
    }
  }
}
