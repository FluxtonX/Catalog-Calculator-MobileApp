import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'screens/onboarding_screen.dart';

import 'screens/splash_screen.dart';
import 'screens/search_artist_screen.dart';
import 'screens/valuation_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('DotEnv load failed: $e');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: dotenv.env['EXPO_PUBLIC_SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  runApp(const MyApp());
}

// Global Router Configuration
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchArtistScreen(),
    ),
    GoRoute(
      path: '/dashboard/:platform/:query',
      builder: (context, state) => ValuationDashboardScreen(
        platform: state.pathParameters['platform'] ?? 'spotify',
        query: state.pathParameters['query'] ?? '',
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const PlaceholderScreen(title: 'Login'),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderScreen(title: 'Dashboard'),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Catalog Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090b), // zinc-950
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10b981), // emerald-500
          secondary: Color(0xFF10b981),
          background: Color(0xFF09090b),
        ),
      ),
      routerConfig: _router,
    );
  }
}

// Temporary Placeholder Screen
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Screen',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
