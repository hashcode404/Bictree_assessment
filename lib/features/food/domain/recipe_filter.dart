import 'food_category.dart';
import 'recipe.dart';
const double kPriceMin = 8;
const double kPriceMax = 20;

enum SortOption {
  none('Default'),
  ratingHigh('Rating: high to low'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  nameAz('Name: A to Z');

  const SortOption(this.label);
  final String label;
}

class RecipeFilter {
  const RecipeFilter({
    this.category,
    this.sort = SortOption.none,
    this.minPrice = kPriceMin,
    this.maxPrice = kPriceMax,
  });

  final FoodCategory? category;
  final SortOption sort;
  final double minPrice;
  final double maxPrice;

  bool get isDefault =>
      category == null &&
      sort == SortOption.none &&
      minPrice <= kPriceMin &&
      maxPrice >= kPriceMax;

  RecipeFilter copyWith({
    FoodCategory? category,
    bool clearCategory = false,
    SortOption? sort,
    double? minPrice,
    double? maxPrice,
  }) {
    return RecipeFilter(
      category: clearCategory ? null : (category ?? this.category),
      sort: sort ?? this.sort,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}
List<Recipe> applyFilter(List<Recipe> items, RecipeFilter filter) {
  final result = items.where((r) {
    final categoryOk = filter.category == null || filter.category!.matches(r);
    final priceOk =
        r.price >= filter.minPrice - 0.001 && r.price <= filter.maxPrice + 0.001;
    return categoryOk && priceOk;
  }).toList();

  switch (filter.sort) {
    case SortOption.none:
      break;
    case SortOption.ratingHigh:
      result.sort((a, b) => b.rating.compareTo(a.rating));
    case SortOption.priceLow:
      result.sort((a, b) => a.price.compareTo(b.price));
    case SortOption.priceHigh:
      result.sort((a, b) => b.price.compareTo(a.price));
    case SortOption.nameAz:
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  return result;
}
