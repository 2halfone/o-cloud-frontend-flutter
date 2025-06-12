import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/service_grid.dart';
import '../widgets/dashboard/logout_dialog.dart';
import '../widgets/dashboard/dashboard_animations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  String _userName = '';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late DashboardAnimations _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _animations = DashboardAnimations(
      fadeController: _fadeController,
      slideController: _slideController,
    );
    
    _animations.startAnimations();
  }  Future<void> _loadUserData() async {
    print('DEBUG dashboard_screen: _loadUserData starting...');
    
    final isAdmin = await _authService.isUserAdmin();
    final userEmail = await _authService.getUserEmail();
    final extractedName = _extractUserName(userEmail ?? '');
    
    print('DEBUG dashboard_screen: isAdmin = $isAdmin');
    print('DEBUG dashboard_screen: userEmail = $userEmail');
    print('DEBUG dashboard_screen: extractedName = $extractedName');
    
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _userName = extractedName;
      });
      print('DEBUG dashboard_screen: State updated - _isAdmin = $_isAdmin, _userName = $_userName');
    }
  }
  String _extractUserName(String email) {
    if (email.isNotEmpty && email.contains('@')) {
      String name = email.split('@')[0];
      return name;
    }
    return 'User'; // Fallback
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
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  // Header with user info and quick actions
                  DashboardHeader(
                    userName: _userName,
                    isAdmin: _isAdmin,
                    onLogout: () => LogoutDialog.show(context),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Welcome Card
                  _buildWelcomeCard(),
                    const SizedBox(height: 32),                  // Services Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: ServiceGrid(isAdmin: _isAdmin),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      Text(
                        _userName.isNotEmpty 
                          ? 'Good ${_getGreeting()}, $_userName!'
                          : 'Good ${_getGreeting()}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your cloud services and monitor applications',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}