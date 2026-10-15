import 'package:catalog_calculator_flutter/screens/auth_screen.dart';
import 'package:catalog_calculator_flutter/screens/onboarding_screen.dart';
import 'package:catalog_calculator_flutter/screens/search_artist_screen.dart';
import 'package:catalog_calculator_flutter/screens/main_navigation_screen.dart';
import 'package:catalog_calculator_flutter/screens/splash_screen.dart';
import 'package:catalog_calculator_flutter/screens/artist_valuation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalog_calculator_flutter/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load();
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
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchArtistScreen(),
    ),
    GoRoute(
      path: '/valuation',
      builder: (context, state) {
        final query = state.uri.queryParameters['query'];
        final artistId = state.uri.queryParameters['artistId'];
        return ArtistValuationScreen(
          query: query,
          artistId: artistId,
        );
      },
    ),
    GoRoute(
      path: '/valuation/:query',
      builder: (context, state) => ArtistValuationScreen(
        query: state.pathParameters['query'] ?? '',
      ),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const ArtistValuationScreen(),
    ),
    GoRoute(
      path: '/dashboard/:platform/:query',
      builder: (context, state) => ArtistValuationScreen(
        query: state.pathParameters['query'] ?? '',
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchArtistCubit(),
      child: MaterialApp.router(
        title: 'Catalog Calculator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}

// Temporary Placeholder Screen
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});
  final String title;

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
