import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? backgroundImagePath;

  const FeatureCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.backgroundImagePath,
  }) : super(key: key);

  @override

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              if (backgroundImagePath != null)
                Positioned.fill(
                  child: Image.asset(
                    backgroundImagePath!,
                    fit: BoxFit.cover,
                  ),
                ),
              
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}