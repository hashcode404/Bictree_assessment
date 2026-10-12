import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/yellow_page.dart';
import '../domain/recipe.dart';
import '../domain/recipe_filter.dart';
import 'providers/food_providers.dart';
import 'widgets/filter_widgets.dart';
import 'widgets/recipe_list_view.dart';
import 'widgets/recipe_widgets.dart';
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _debounce = Duration(milliseconds: 400);
  static const _autoFillBelow = 6;

  final _controller = TextEditingController();
  Timer? _timer;
  String _query = '';
  RecipeFilter _filter = const RecipeFilter();

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    final catalog = ref.watch(recipesControllerProvider);
    final catalogController = ref.read(recipesControllerProvider.notifier);

    final AsyncValue<List<Recipe>> source = searching
        ? ref.watch(searchResultsProvider(_query))
        : catalog.whenData((s) => s.items);

    final fromCache = !searching && (catalog.value?.fromCache ?? false);

    return YellowPage(
      title: 'Search',
      showBack: true,
      child: Column(
        children: [
          if (fromCache) OfflineBanner(onRetry: catalogController.refresh),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search dishes',
                prefixIcon: const Icon(Icons.search, color: AppColors.orange),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: _clear,
                        icon: const Icon(Icons.close, color: AppColors.orange),
                      ),
              ),
            ),
          ),
          CategoryChips(
            selected: _filter.category,
            onSelected: (c) => setState(() {
              _filter = _filter.copyWith(category: c, clearCategory: c == null);
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Text('Sort By',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SortDropdown(
                      value: _filter.sort,
                      onChanged: (s) =>
                          setState(() => _filter = _filter.copyWith(sort: s)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _PriceRange(
            min: _filter.minPrice,
            max: _filter.maxPrice,
            onChanged: (values) => setState(() {
              _filter = _filter.copyWith(
                minPrice: values.start,
                maxPrice: values.end,
              );
            }),
          ),
          Expanded(
            child: source.when(
              loading: () => const RecipeListSkeleton(),
              error: (e, _) => ErrorView(
                message: messageOf(e),
                onRetry: () {
                  if (searching) {
                    ref.invalidate(searchResultsProvider(_query));
                  } else {
                    ref.invalidate(recipesControllerProvider);
                  }
                },
              ),
              data: (items) {
                final visible = applyFilter(items, _filter);
                final state = catalog.value;
                final canLoadMore = !searching &&
                    state != null &&
                    state.hasMore &&
                    !state.isLoadingMore &&
                    !state.loadMoreFailed;
                if (canLoadMore && visible.length < _autoFillBelow) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => catalogController.loadMore(),
                  );
                }
                return RecipeListView(
                  items: visible,
                  heroSource: 'search',
                  emptyTitle: searching ? 'No results' : 'No dishes found',
                  emptyMessage: searching
                      ? 'Nothing matches "$_query". Try another word.'
                      : 'Try another category or price range.',
                  onRefresh: () async {
                    if (searching) {
                      ref.invalidate(searchResultsProvider(_query));
                    } else {
                      await catalogController.refresh();
                    }
                  },
                  onLoadMore: searching ? null : catalogController.loadMore,
                  footer: (!searching && state != null)
                      ? LoadMoreFooter(
                          state: state,
                          onRetry: catalogController.loadMore,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRange extends StatelessWidget {
  const _PriceRange({
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final double min;
  final double max;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${formatMoney(min)} - ${formatMoney(max)}',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.inputFill,
              thumbColor: AppColors.orange,
              overlayColor: AppColors.peach,
            ),
            child: RangeSlider(
              values: RangeValues(min, max),
              min: kPriceMin,
              max: kPriceMax,
              divisions: 24,
              labels: RangeLabels(formatMoney(min), formatMoney(max)),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
