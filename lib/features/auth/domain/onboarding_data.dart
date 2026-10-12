import 'package:flutter/material.dart';

class OnboardingData {
  const OnboardingData({
    required this.image,
    required this.icon,
    required this.title,
    required this.body,
  });
  final String image;
  final IconData icon; 
  final String title;
  final String body;
}