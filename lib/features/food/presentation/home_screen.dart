import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/error/failure.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/page_dots.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../cart/presentation/providers/cart_providers.dart';
import '../domain/food_category.dart';
import '../domain/recipe.dart';
import 'providers/food_providers.dart';
import 'widgets/recipe_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesControllerProvider);
    final best = ref.watch(bestSellersProvider);
    final controller = ref.read(recipesControllerProvider.notifier);
    final fromCache = recipes.value?.fromCache ?? false;

    final List<Widget> body = recipes.when<List<Widget>>(
      loading: () => const [_SkeletonSliver()],
      error: (e, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: messageOf(e),
            onRetry: () => ref.invalidate(recipesControllerProvider),
          ),
        ),
      ],
      data: (state) => _dataSlivers(context, state, best, controller),
    );

    return AnnotatedRegion(
      value: yellowStatusBar,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 400) {
              controller.loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            color: AppColors.orange,
            edgeOffset: MediaQuery.paddingOf(context).top,
            onRefresh: controller.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),
                if (fromCache)
                  SliverToBoxAdapter(
                    child: OfflineBanner(onRetry: controller.refresh),
                  ),
                const SliverToBoxAdapter(child: _CategoryRow()),
                ...body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _dataSlivers(
  BuildContext context,
  RecipesState state,
  List<Recipe> best,
  RecipesController controller,
) {
  if (state.items.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          title: 'No dishes yet',
          icon: Icons.search_off_rounded,
          message: 'We could not find any food right now.',
          onRetry: controller.refresh,
        ),
      ),
    ];
  }

  return [
    SliverToBoxAdapter(
      child: _SectionHeader(
        title: 'Best Seller',
        actionLabel: 'View All',
        onAction: () => context.go(AppRoutes.menu),
      ),
    ),
    SliverToBoxAdapter(child: _BestSellerList(recipes: best)),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: _PromoBanner(recipes: best.take(3).toList()),
      ),
    ),
    const SliverToBoxAdapter(child: _SectionHeader(title: 'Recommend')),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _RecommendCard(recipe: state.items[i]),
          childCount: state.items.length,
        ),
      ),
    ),
    SliverToBoxAdapter(
      child: LoadMoreFooter(state: state, onRetry: controller.loadMore),
    ),
  ];
}


(String, String) _greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return ('Good Morning', "Rise And Shine! It's Breakfast Time");
  if (h < 17) return ('Good Afternoon', "Hungry? It's Lunch Time");
  return ('Good Evening', "Relax! It's Dinner Time");
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final (greeting, tagline) = _greetingFor(DateTime.now());
    final name = ref.watch(authControllerProvider.select((s) => s.user))
            ?.firstName ??
        '';
    final cartCount = ref.watch(cartCountProvider);

    return Container(
      color: AppColors.yellow,
      padding: EdgeInsets.only(top: top + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _SearchPill(
                    onTap: () => context.push(AppRoutes.search),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.cart),
                  child: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    backgroundColor: AppColors.text,
                    textColor: Colors.white,
                    child: _iconBox(Icons.shopping_cart_outlined),
                  ),
                ),
                const SizedBox(width: 8),
                const _ProfileMenu(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                name.isEmpty ? greeting : '$greeting, $name',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              tagline,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 16, right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Search',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _iconBox(IconData icon) => Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: AppColors.orange),
    );

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    return PopupMenuButton<String>(
      tooltip: 'Account',
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authControllerProvider.notifier).logout();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(user?.displayName ?? 'Guest'),
        ),
        const PopupMenuItem<String>(value: 'logout', child: Text('Log out')),
      ],
      child: _iconBox(Icons.person_outline),
    );
  }
}


class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final c in FoodCategory.values) _CategoryItem(category: c),
              ],
            ),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
        ],
      ),
    );
  }
}

class _CategoryItem extends ConsumerWidget {
  const _CategoryItem({required this.category});
  final FoodCategory category;

  static IconData _iconFor(FoodCategory c) => switch (c) {
        FoodCategory.snacks => Icons.fastfood_outlined,
        FoodCategory.meal => Icons.restaurant,
        FoodCategory.vegan => Icons.eco_outlined,
        FoodCategory.dessert => Icons.cake_outlined,
        FoodCategory.drinks => Icons.local_drink_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () {
        ref.read(menuFilterProvider.notifier).setCategory(category);
        context.go(AppRoutes.menu);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(_iconFor(category), color: AppColors.orange, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            category.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.orange),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class _BestSellerList extends StatelessWidget {
  const _BestSellerList({required this.recipes});
  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: recipes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final r = recipes[i];
          return GestureDetector(
            onTap: () => openFood(context, r, 'best'),
            child: SizedBox(
              width: 78,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RecipeImage(url: r.image),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: PriceTag(price: r.price),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class _PromoBanner extends StatefulWidget {
  const _PromoBanner({required this.recipes});
  final List<Recipe> recipes;

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            itemCount: widget.recipes.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _PromoCard(recipe: widget.recipes[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        PageDots(count: widget.recipes.length, current: _page),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openFood(context, recipe, 'promo'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: AppColors.orange,
                padding: const EdgeInsets.all(14),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Experience our\ndelicious new dish',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '30% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: SizedBox.expand(child: RecipeImage(url: recipe.image)),
            ),
          ],
        ),
      ),
    );
  }
}


class _RecommendCard extends StatelessWidget {
  const _RecommendCard({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openFood(context, recipe, 'home'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: recipeHeroTag('home', recipe.id),
              child: RecipeImage(url: recipe.image),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 18, 70, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xAA000000)],
                  ),
                ),
                child: Text(
                  recipe.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: RatingChip(rating: recipe.rating),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: PriceTag(price: recipe.price),
            ),
          ],
        ),
      ),
    );
  }
}


class _SkeletonSliver extends StatelessWidget {
  const _SkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE6E6E6),
        highlightColor: const Color(0xFFF5F5F5),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bone(width: 110, height: 20),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Bone(height: 118, radius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: _Bone(height: 118, radius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: _Bone(height: 118, radius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: _Bone(height: 118, radius: 18)),
                ],
              ),
              SizedBox(height: 20),
              _Bone(height: 140, radius: 22),
              SizedBox(height: 24),
              _Bone(width: 120, height: 20),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Bone(height: 130, radius: 20)),
                  SizedBox(width: 14),
                  Expanded(child: _Bone(height: 130, radius: 20)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({this.width, this.height, this.radius = 8});
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
