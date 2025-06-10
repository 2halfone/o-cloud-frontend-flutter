import 'package:flutter/material.dart';
import '../widgets/settings/settings_header.dart';
import '../widgets/settings/settings_sections.dart';
import '../widgets/settings/settings_animations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late SettingsAnimations _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animations = SettingsAnimations(
      fadeController: _fadeController,
      slideController: _slideController,
    );
    
    _animations.startAnimations();
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: FadeTransition(
        opacity: _animations.fadeAnimation,
        child: SlideTransition(
          position: _animations.slideAnimation,
          child: const SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with navigation
                  SettingsHeader(),
                  
                  SizedBox(height: 24),
                  
                  // Settings Sections
                  SettingsSections(),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}