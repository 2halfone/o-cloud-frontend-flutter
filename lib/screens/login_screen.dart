import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Chiamata al nuovo metodo login che ritorna Map<String, dynamic>
      final loginResult = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      // Estrazione del user_id dal risultato
      final userId = loginResult['user_id']?.toString();
        // Navigazione a /dashboard passando il user_id come argomento
      if (userId != null) {
        Navigator.pushReplacementNamed(
          context, 
          '/dashboard',
          arguments: {'user_id': userId},
        );
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              child: Container(
                width: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Go Cloud Frontend',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Email is required';
              if (!value!.contains('@')) return 'Invalid email format';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Password is required';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
                    'Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: Text(
              'Don\'t have an account? Register',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
