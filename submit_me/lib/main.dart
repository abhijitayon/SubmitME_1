import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:submit_me/auth_page.dart';
import 'package:submit_me/login_page.dart';
import 'package:submit_me/registration_page.dart';
import 'package:submit_me/pages/main_navigation.dart';
import 'package:submit_me/services/supabase_service.dart';

void main() async {
  // Required by Flutter before initializing platform channels or plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if credentials have been configured
  if (SupabaseService.isConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SubmitME',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 200, 217, 236),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF565B61),
          brightness: Brightness.light,
          surface: const Color(0xFFF2F3F4),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 70, 136, 216),
          foregroundColor: Colors.white,
        ),
      ),
      // AuthGate automatically directs between landing page and the main application
      home: const AuthGate(),
      routes: {
        '/home': (context) => const AuthLandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/dashboard': (context) => const MainNavigation(),
      },
    );
  }
}

/// A simple gatekeeper widget that automatically routes users based on their
/// Supabase authentication state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If credentials are not configured yet, show the landing page
    if (!SupabaseService.isConfigured) {
      return const AuthLandingPage();
    }

    // StreamBuilder listens for auth changes (login, logout, token refresh).
    // In Flutter Web, Supabase stores session tokens in localStorage automatically.
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          // User is authenticated -> show the main SubmitME application
          return const MainNavigation();
        } else {
          // User is not authenticated -> show welcome/landing screen
          return const AuthLandingPage();
        }
      },
    );
  }
}
