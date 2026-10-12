import 'package:bictree_assessment/features/auth/domain/onboarding_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';

const _pages = [
  OnboardingData(
    image: 'assets/images/onboarding-3.png',
    icon: Icons.receipt_long_outlined,
    title: 'Order For Food',
    body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
        'sed do eiusmod tempor incididunt ut labore et dolore magna.',
  ),
  OnboardingData(
    image: 'assets/images/onboarding-1.png',
    icon: Icons.credit_card_outlined,
    title: 'Easy Payment',
    body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
        'sed do eiusmod tempor incididunt ut labore et dolore magna.',
  ),
  OnboardingData(
    image: 'assets/images/onboarding-2.png',
    icon: Icons.delivery_dining_outlined,
    title: 'Fast Delivery',
    body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
        'sed do eiusmod tempor incididunt ut labore et dolore magna.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  void _finish() => context.go(AppRoutes.login);

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.yellow,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor:
            AppColors.yellow,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _OnboardingPage(
                  data: _pages[i],
                  index: i,
                  total: _pages.length,
                  isLast: i == _pages.length - 1,
                  onNext: _next,
                ),
              ),
              if (!_isLast)
                Positioned(
                  top: 12,
                  right: 16,
                  child: TextButton(
                    onPressed: _finish,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Skip',
                            style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.w700)),
                        Icon(Icons.chevron_right,
                            size: 18, color: AppColors.orange),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
  });

  final OnboardingData data;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: Image.asset(
              data.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: AppColors.inputFill),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(data.icon, size: 36, color: AppColors.orange),
                const SizedBox(height: 12),
                Text(
                  data.title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _Dots(count: total, current: index),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(124, 38),
                  ),
                  child: Text(isLast ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: active ? AppColors.orange : AppColors.inputFill,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
