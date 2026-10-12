import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: i == current ? AppColors.orange : AppColors.inputFill,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
