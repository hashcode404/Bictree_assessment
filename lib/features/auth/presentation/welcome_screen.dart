import 'package:bictree_assessment/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.orange,
        statusBarIconBrightness: Brightness.light, 
        statusBarBrightness: Brightness.dark, 
      ),
      child: Scaffold(
        backgroundColor: AppColors.orange,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/logos/logo2.svg',
                width: 205,
                height: 250,
              ),
              const SizedBox(height: 20),
              const Text(
                "Lorem ipsum dolor sit amet, consectetur \nadipiscing elit, sed do eiusmod.",
                style: TextStyle(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppRoutes.onboarding),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.orange,
                ),
                child: const Text("Log in"),
              ),
              const SizedBox(height: 5),
              FilledButton(
                onPressed: () {
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellowTwo,
                  foregroundColor: AppColors.orange,
                ),
                child: const Text("Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
