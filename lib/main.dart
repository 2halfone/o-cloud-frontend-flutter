import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/user_detail_screen.dart';

void main() {
  print('DEBUG main.dart: App starting...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Go Cloud Backend',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthWrapper(),        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const WelcomeScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/user-detail') {
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => UserDetailScreen(userId: userId),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
      return FutureBuilder<bool>(
      future: authService.isLoggedIn(),
      builder: (context, snapshot) {
        print('DEBUG AuthWrapper: ConnectionState = ${snapshot.connectionState}');
        print('DEBUG AuthWrapper: Is logged in = ${snapshot.data}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.data == true) {
          print('DEBUG AuthWrapper: Navigating to WelcomeScreen (Dashboard)');
          return const WelcomeScreen();
        } else {
          print('DEBUG AuthWrapper: Navigating to LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}
