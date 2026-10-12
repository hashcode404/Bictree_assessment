import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/providers/cart_providers.dart';
import '../theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: shell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavButton(
                  tooltip: 'Home',
                  icon: Icons.home_outlined,
                  selected: shell.currentIndex == 0,
                  onTap: () => _go(0),
                ),
                _NavButton(
                  tooltip: 'Menu',
                  icon: Icons.restaurant_menu,
                  selected: shell.currentIndex == 1,
                  onTap: () => _go(1),
                ),
                _NavButton(
                  tooltip: 'Cart',
                  icon: Icons.shopping_cart_outlined,
                  badge: cartCount,
                  selected: shell.currentIndex == 2,
                  onTap: () => _go(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: selected ? const Color(0x38FFFFFF) : null,
      ),
      icon: Badge(
        isLabelVisible: badge > 0,
        label: Text('$badge'),
        backgroundColor: AppColors.yellow,
        textColor: AppColors.text,
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
