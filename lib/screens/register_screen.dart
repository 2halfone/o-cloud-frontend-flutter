import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();  final _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    print('🚀 Starting registration process...');
    setState(() => _isLoading = true);

    try {
      print('Attempting to register with email: ${_emailController.text}');
      
      await _authService.register(
        _emailController.text,
        _passwordController.text,
      );
      
      print('✅ Registration completed successfully!');
      
      if (mounted) {
        // Mostra messaggio di successo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Welcome!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Vai direttamente alla dashboard invece che al login
        final userName = _emailController.text.split('@')[0];
        
        Navigator.pushReplacementNamed(
          context, 
          '/dashboard',
          arguments: {
            'user_id': _emailController.text, // Usa email come identificativo temporaneo
            'user_name': userName,  // Nome estratto dall'email
            'is_new_user': true,
          },
        );
      }
    } catch (e) {
      print('❌ Registration failed with error: $e');
      
      if (mounted) {
        // Gestione errori migliorata
        String errorMessage;
        if (e.toString().contains('USER_EXISTS') || e.toString().contains('409')) {
          errorMessage = 'Email already registered. Please use a different email or sign in.';
        } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
          errorMessage = 'Connection problem. Please check your internet connection.';
        } else if (e.toString().contains('server') || e.toString().contains('500')) {
          errorMessage = 'Server error. Please try again in a few minutes.';
        } else {
          errorMessage = 'Registration failed. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              Theme.of(context).colorScheme.primary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Card(
                  elevation: 20,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667eea),
                                const Color(0xFF764ba2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_add,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              const Color(0xFF667eea),
                              const Color(0xFF764ba2),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Go Cloud Frontend',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your account',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildRegisterForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            icon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: true,
            icon: Icons.lock_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            obscureText: true,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Register',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ),
          const SizedBox(height: 16),          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Already have an account? Sign In',
              style: TextStyle(color: const Color(0xFF667eea)),
            ),
          ),
        ],
      ),
    );
  }
}
