import 'dart:io';

import 'package:catalog_calculator_flutter/core/theme/app_theme.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_cubit.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/dashboard/models/valuation_models.dart';
import 'artist_valuation_screen.dart';

class SearchArtistScreen extends StatelessWidget {
  const SearchArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchArtistView();
  }
}

class SearchArtistView extends StatefulWidget {
  const SearchArtistView({super.key});

  @override
  State<SearchArtistView> createState() => _SearchArtistViewState();
}

class _SearchArtistViewState extends State<SearchArtistView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _royaltyController = TextEditingController(text: '100');
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Multiple Platform Selection
  final Map<String, bool> _platforms = {
    'spotify': true,
    'youtube': true,
    'apple': true,
  };

  // Results Options State
  String _currency = 'USD';
  double _royaltyShare = 100;

  final Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'GBP': 0.79,
    'EUR': 0.92,
    'AUD': 1.53,
    'CAD': 1.36,
    'CHF': 0.88,
    'JPY': 150.0,
    'CNY': 7.15,
    'INR': 83.0,
    'ZAR': 19.0,
    'BRL': 5.0,
    'MXN': 17.0,
    'NZD': 1.65,
    'SEK': 10.4,
    'NOK': 10.6,
    'DKK': 6.8,
    'SGD': 1.34,
    'HKD': 7.82,
  };

  bool _isSigningInWithGoogle = false;

  Future<void> _handleGoogleSignInAndProceed() async {
    setState(() => _isSigningInWithGoogle = true);

    try {
      const webClientId = '660487613110-68oirrtmp57ovl0gbikcmbdthdv2g5a3.apps.googleusercontent.com';
      const iosClientId = '660487613110-mf4qoet2e6ac1s7ov18m4h1e98n4bq4a.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? iosClientId : null,
        serverClientId: webClientId,
      );

      // Ensure fresh Google account selection prompt every time
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled login dialog
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'No Auth Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_search_query', _searchController.text);
      await prefs.setString(
        'last_search_platform',
        _platforms.keys.firstWhere((k) => _platforms[k] == true, orElse: () => 'spotify'),
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ArtistValuationScreen(
              query: _searchController.text,
              selectedPlatforms: _platforms,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Email Login',
              textColor: Colors.amber,
              onPressed: () => context.push('/login'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningInWithGoogle = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }



  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final keyContext = _resultsKey.currentContext;
        if (keyContext != null) {
          Scrollable.ensureVisible(
            keyContext,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            alignment: 0.0,
          );
        } else if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
  }

  Future<void> _handleCalculate([String? overrideQuery, bool pushScreen = false]) async {
    final query = (overrideQuery ?? _searchController.text).trim();
    if (query.isEmpty) return;
    
    if (overrideQuery != null && _searchController.text != overrideQuery) {
      _searchController.text = overrideQuery;
    }

    FocusScope.of(context).unfocus();

    await context.read<SearchArtistCubit>().searchArtist(
      query: query,
      platforms: _platforms,
    );

    if (pushScreen && mounted && context.read<SearchArtistCubit>().state is SearchArtistLoaded) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArtistValuationScreen(
            query: query,
            selectedPlatforms: _platforms,
          ),
        ),
      );
    } else if (mounted && context.read<SearchArtistCubit>().state is SearchArtistLoaded) {
      // Auto move down smoothly to results, exactly like website LandingPage.jsx resultsRef.scrollIntoView
      _scrollToResults();
    }
  }

  String _formatLocalCurrency(double value) {
    final adjustedValue = value * (_royaltyShare / 100);
    final rate = _exchangeRates[_currency] ?? 1.0;
    final converted = adjustedValue * rate;
    
    final currencySymbols = <String, String>{
      'USD': r'$',
      'GBP': '£',
      'EUR': '€',
      'AUD': r'A$',
      'CAD': r'C$',
      'CHF': 'CHF',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'ZAR': 'R',
      'BRL': r'R$',
      'MXN': r'$',
      'NZD': r'NZ$',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'SGD': r'S$',
      'HKD': r'HK$',
    };
    
    final symbol = currencySymbols[_currency] ?? r'$';
    
    final numStr = converted.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},'
    );
    
    return '$symbol$numStr';
  }

  String _formatQuickRead(double value) {
    final adjustedValue = value * (_royaltyShare / 100);
    final rate = _exchangeRates[_currency] ?? 1.0;
    final converted = adjustedValue * rate;
    
    final currencySymbols = <String, String>{
      'USD': r'$', 'GBP': '£', 'EUR': '€', 'AUD': r'A$', 'CAD': r'C$', 
      'CHF': 'CHF', 'JPY': '¥', 'CNY': '¥', 'INR': '₹', 'ZAR': 'R', 
      'BRL': r'R$', 'MXN': r'$', 'NZD': r'NZ$', 'SEK': 'kr', 
      'NOK': 'kr', 'DKK': 'kr', 'SGD': r'S$', 'HKD': r'HK$',
    };
    final symbol = currencySymbols[_currency] ?? r'$';
    
    if (converted >= 1000000) {
      return '≈ $symbol${(converted / 1000000).toStringAsFixed(2)} million';
    } else if (converted >= 1000) {
      return '≈ $symbol${(converted / 1000).toStringAsFixed(2)} thousand';
    }
    return '≈ $symbol${converted.toStringAsFixed(0)}';
  }

  Widget _buildPlatformOption(String id, String name, IconData icon, Color activeColor) {
    final isSelected = _platforms[id] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _platforms[id] = !isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBackground,
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.4) : AppTheme.borderColor,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFF1A2333),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isSelected 
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Icon(icon, color: activeColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchArtistCubit, SearchArtistState>(
      listener: (context, state) {
        if (state is SearchArtistLoaded) {
          _scrollToResults();
        }
      },
      builder: (context, state) {
        final isSearching = state is SearchArtistLoading;
        final errorMessage = state is SearchArtistError ? state.message : null;
        final estimatedValue = state is SearchArtistLoaded ? state.valuationData.estimatedValue : null;
        final artistData = state is SearchArtistLoaded ? state.artistData : null;

        final showResults = estimatedValue != null;
        final hasInput = _searchController.text.trim().isNotEmpty;
        
        // Accurate website colors
        final bgColor = AppTheme.scaffoldBackground;
        const brandCyan = AppTheme.brandCyan;
        
        return Scaffold(
          backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Top Logo (Website header: Hexagon/Bar icon + Catalog [Calculator by CFA])
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: brandCyan.withValues(alpha: 0.1),
                        border: Border.all(color: brandCyan.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calculate, color: brandCyan, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text.rich(
                      TextSpan(
                        text: 'Catalog ',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Calculator',
                            style: TextStyle(color: brandCyan, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // Badge (Option 1 badge from website)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, color: Color(0xFF60A5FA), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'OPTION 1 • INSTANT ESTIMATE',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF60A5FA),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Hero Text matching LandingPage.jsx
                Text.rich(
                  TextSpan(
                    text: "What's Your\n",
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -1.0,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Catalog',
                        style: TextStyle(color: brandCyan),
                      ),
                      TextSpan(
                        text: ' Worth?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ]
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 14),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Search for an artist, select data sources, and instantly get an estimated catalog valuation.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 36),
                
                // Main Container (Web Card: #0B101A with border #1A2333)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldBackground,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                            textInputAction: TextInputAction.done,
                            onChanged: (text) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search artist...',
                              hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.3)),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Icon(Icons.search, color: Colors.white54, size: 20),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            onSubmitted: (_) => _handleCalculate(),
                          ),
                        ),
                        
                        const SizedBox(height: 14),

                        // Suggested Artists
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (final artist in const [
                                'Bad Bunny',
                                'Taylor Swift',
                                'Drake',
                                'The Weeknd',
                                'Ariana Grande'
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: Text(artist),
                                    avatar: const Icon(Icons.trending_up, size: 14, color: brandCyan),
                                    backgroundColor: AppTheme.scaffoldBackground,
                                    side: const BorderSide(color: AppTheme.borderColor),
                                    labelStyle: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    onPressed: () {
                                      _searchController.text = artist;
                                      setState(() {});
                                      _handleCalculate(artist, true);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        Text(
                          'DATA SOURCES',
                          style: GoogleFonts.inter(
                            color: brandCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        
                        // Platform checkboxes
                        _buildPlatformOption('spotify', 'Spotify', Icons.music_note, AppTheme.spotifyGreen),
                        _buildPlatformOption('youtube', 'YouTube', Icons.play_circle_filled, AppTheme.youtubeRed),
                        _buildPlatformOption('apple', 'Apple Music', Icons.apple, AppTheme.appleSilver),

                        const SizedBox(height: 16),
                        
                        // Info banner matching web
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            border: Border.all(color: brandCyan.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: brandCyan, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'THIS ESTIMATE IS AN INDICATION BASED ON YOUR TOP 10 TRACKS',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        
                        // Calculate Button (Matching web gradient button)
                        GestureDetector(
                          onTap: (hasInput && !isSearching) ? _handleCalculate : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: hasInput
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFF1E293B).withValues(alpha: 0.4), const Color(0xFF0F172A).withValues(alpha: 0.4)],
                              ),
                              border: Border.all(
                                color: hasInput ? AppTheme.borderColorSubtle : AppTheme.borderColor,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: hasInput ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                )
                              ] : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSearching)
                                  const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(brandCyan),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.calculate, 
                                    color: hasInput ? brandCyan : Colors.white24, 
                                    size: 20
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  isSearching ? 'Calculating...' : 'Calculate Catalog Value',
                                  style: GoogleFonts.inter(
                                    color: hasInput ? Colors.white : Colors.white30,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.red.shade400, fontSize: 14),
                    ),
                  ),

                // Valuation Results Section
                if (showResults)
                  Container(
                    key: _resultsKey,
                    child: _buildResultsSection(estimatedValue, artistData),
                  )
                else
                  const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  String _getPlatformName() {
    final selected = <String>[];
    if (_platforms['spotify'] == true) selected.add('SPOTIFY');
    if (_platforms['apple'] == true) selected.add('APPLE MUSIC');
    if (_platforms['youtube'] == true) selected.add('YOUTUBE');
    
    if (selected.length == 3) return 'ALL PLATFORMS';
    return selected.join(' & ');
  }

  String _getNoteText() {
    final count = _platforms.values.where((v) => v).length;
    if (count == 1) {
      var name = _platforms.keys.firstWhere((k) => _platforms[k] == true);
      name = name == 'apple' ? 'Apple Music' : (name == 'youtube' ? 'YouTube' : 'Spotify');
      return 'Note: This is your catalog valuation calculated for $name only.';
    }
    return 'Note: This is your catalog valuation calculated across combined platforms.';
  }

  Widget _buildResultsSection(double? estimatedValue, ArtistProfileModel? artistData) {
    if (estimatedValue == null) return const SizedBox.shrink();
    
    final artistName = artistData?.title ?? _searchController.text;
    String? imageUrl = artistData?.imageUrl;
    if (imageUrl != null && imageUrl.isEmpty) {
      imageUrl = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          if (imageUrl != null)
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.brandCyan.withValues(alpha: 0.5), width: 2),
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandCyan.withValues(alpha: 0.2),
                    blurRadius: 20,
                  )
                ]
              ),
            ),
            
          Text(
            artistName,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'ESTIMATED CATALOG VALUE',
            style: GoogleFonts.inter(
              color: AppTheme.brandCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                _formatLocalCurrency(estimatedValue),
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                  border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'QUICK READ',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatQuickRead(estimatedValue),
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_getPlatformName()} @ ${_royaltyShare.toStringAsFixed(0)}% ROYALTY SHARE',
              style: GoogleFonts.inter(color: AppTheme.brandCyan, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              border: Border.all(color: AppTheme.brandCyan.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.info, color: AppTheme.brandCyan, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getNoteText(),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Controls Box (Website matching: #0B101A with border #1A2333)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Royalty share', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldBackground,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (_royaltyShare > 0) {
                                    setState(() {
                                      _royaltyShare -= 1;
                                      _royaltyController.text = _royaltyShare.toString();
                                    });
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  child: Icon(Icons.remove, size: 16, color: Colors.white54),
                                ),
                              ),
                              SizedBox(
                                width: 42,
                                child: TextField(
                                  controller: _royaltyController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(bottom: 12),
                                    suffixText: '%',
                                    suffixStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      final parsed = double.tryParse(value);
                                      if (parsed != null) setState(() => _royaltyShare = parsed);
                                    }
                                  },
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (_royaltyShare < 100) {
                                    setState(() {
                                      _royaltyShare += 1;
                                      _royaltyController.text = _royaltyShare.toString();
                                    });
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  child: Icon(Icons.add, size: 16, color: Colors.white54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _royaltyShare = 100.0;
                              _royaltyController.text = '100.0';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.brandCyan.withValues(alpha: 0.12),
                              border: Border.all(color: AppTheme.brandCyan.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '100%',
                              style: GoogleFonts.inter(color: AppTheme.brandCyan, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Currency', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currency,
                          dropdownColor: AppTheme.cardBackground,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() => _currency = newValue);
                            }
                          },
                          items: _exchangeRates.keys.toList()
                              .map<DropdownMenuItem<String>>((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 1. Sign in with Google Button (Matching Screenshot 2)
          GestureDetector(
            onTap: _isSigningInWithGoogle ? null : _handleGoogleSignInAndProceed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSigningInWithGoogle)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1E293B),
                      ),
                    )
                  else
                    SvgPicture.string(
                      '''<svg width="20" height="20" viewBox="0 0 24 24">
                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                      </svg>''',
                      width: 20,
                      height: 20,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Sell Your Catalog Now Button (Matching Screenshot 2)
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://www.creativefundingagency.com/application');
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(uri);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open application link: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC29C5B), Color(0xFFA27A3F)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC29C5B).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sell Your Catalog Now',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
