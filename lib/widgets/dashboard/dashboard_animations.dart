import 'package:flutter/material.dart';

class DashboardAnimations {
  final AnimationController fadeController;
  final AnimationController slideController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;

  DashboardAnimations({
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
    Future.delayed(const Duration(milliseconds: 300), () {
      slideController.forward();
    });
  }

  void dispose() {
    fadeController.dispose();
    slideController.dispose();
  }
}
