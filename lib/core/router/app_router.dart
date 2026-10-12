import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/fingerprint_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/password_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/confirm_order_screen.dart';
import '../../features/food/presentation/food_detail_args.dart';
import '../../features/food/presentation/food_detail_screen.dart';
import '../../features/food/presentation/home_screen.dart';
import '../../features/food/presentation/menu_screen.dart';
import '../../features/food/presentation/search_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

export 'app_routes.dart';

const _publicRoutes = {
  AppRoutes.welcome,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.password,
  AppRoutes.fingerprint,
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(
    authControllerProvider.select((s) => s.status),
    (_, __) => refresh.value++,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;

      switch (status) {
        case AuthStatus.unknown:
          return loc == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.unauthenticated:
          if (loc == AppRoutes.splash) return AppRoutes.welcome;
          return _publicRoutes.contains(loc) ? null : AppRoutes.login;
        case AuthStatus.authenticated:
          return (loc == AppRoutes.splash || _publicRoutes.contains(loc))
              ? AppRoutes.home
              : null;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: AppRoutes.password, builder: (_, __) => const PasswordScreen()),
      GoRoute(
          path: AppRoutes.fingerprint,
          builder: (_, __) => const FingerprintScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.menu, builder: (_, __) => const MenuScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),
          ]),
        ],
      ),
      GoRoute(path: AppRoutes.search, builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: AppRoutes.food,
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _NotFoundScreen();
          final extra = state.extra;
          return FoodDetailScreen(
            id: id,
            args: extra is FoodDetailArgs ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.confirm,
        builder: (_, __) => const ConfirmOrderScreen(),
      ),
    ],
  );
});

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('This page does not exist.')),
    );
  }
}
