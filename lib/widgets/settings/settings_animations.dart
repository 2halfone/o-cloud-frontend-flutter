import 'package:flutter/material.dart';

class SettingsAnimations {
  final AnimationController fadeController;
  final AnimationController slideController;
  
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  SettingsAnimations({
    required this.fadeController,
    required this.slideController,
  }) {
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeInOut,
    ));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void startAnimations() {
    fadeController.forward();
    slideController.forward();
  }

  void dispose() {
    fadeController.dispose();
    slideController.dispose();
  }
}