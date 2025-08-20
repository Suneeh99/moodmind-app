import 'package:flutter/material.dart';

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final List<Color> gradientColors;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.gradientColors,
    required this.icon,
  });
}