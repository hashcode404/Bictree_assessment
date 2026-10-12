import 'dart:convert';

import 'package:hive/hive.dart';

import '../domain/recipe_repository.dart';
import 'recipe_model.dart';

abstract class RecipeCache {
  Future<void> saveFirstPage(RecipePage page);

  RecipePage? readFirstPage();
}

class HiveRecipeCache implements RecipeCache {
  HiveRecipeCache(this._box);
  final Box<String> _box;

  static const _key = 'first_page';

  @override
  Future<void> saveFirstPage(RecipePage page) {
    final json = jsonEncode({
      'total': page.total,
      'recipes': page.items.map(RecipeModel.toJson).toList(),
    });
    return _box.put(_key, json);
  }

  @override
  RecipePage? readFirstPage() {
    final raw = _box.get(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = (map['recipes'] as List)
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return RecipePage(
        items: items,
        total: (map['total'] as num).toInt(),
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }
}
