import 'dart:convert';
import 'dart:io';

import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_cubit.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchArtistScreen extends StatelessWidget {
  const SearchArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchArtistCubit(),
      child: const SearchArtistView(),
    );
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
    _fadeController.dispose();
    super.dispose();
  }

  double _parseNumber(dynamic str) {
    if (str == null) return 0;
    if (str is num) return str.toDouble();
    final upper = str.toString().toUpperCase();
    if (upper.contains('B')) return double.parse(upper.replaceAll('B', '')) * 1e9;
    if (upper.contains('M')) return double.parse(upper.replaceAll('M', '')) * 1e6;
    if (upper.contains('K')) return double.parse(upper.replaceAll('K', '')) * 1e3;
    return double.tryParse(upper.replaceAll(RegExp(','), '')) ?? 0;
  }


  Future<void> _handleCalculate([String? overrideQuery]) async {
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected 
                  ? const Icon(Icons.check, size: 16, color: Colors.black) // Dark icon inside bright box
                  : null,
            ),
            const SizedBox(width: 16),
            Icon(icon, color: isSelected ? activeColor : Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchArtistCubit, SearchArtistState>(
      builder: (context, state) {
        final isSearching = state is SearchArtistLoading;
        final errorMessage = state is SearchArtistError ? state.message : null;
        final estimatedValue = state is SearchArtistLoaded ? state.estimatedValue : null;
        final artistData = state is SearchArtistLoaded ? state.artistData : null;

        final showResults = estimatedValue != null;
        final hasInput = _searchController.text.trim().isNotEmpty;
        
        // Very dark emerald background color matching the image
        const bgColor = Color(0xFF041510);
        const brandGreen = Color(0xFF34d399); // Bright green
        
        return Scaffold(
          backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Top Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.1),
                        border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.bar_chart, color: brandGreen, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Catalog Calculator',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: brandGreen.withValues(alpha: 0.1),
                    border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: brandGreen, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'STEP 1 - SELECT ARTIST',
                        style: GoogleFonts.inter(
                          color: brandGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Hero Text
                Text.rich(
                  TextSpan(
                    text: "What's Your\n",
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Catalog',
                        style: TextStyle(color: Color(0xFF34d399)), // Inherits w900 and font family
                      ),
                      TextSpan(
                        text: ' Worth?',
                        style: TextStyle(color: Colors.white), // Inherits w900 and font family
                      ),
                    ]
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Search for an artist, select data sources, and instantly get an estimated catalog valuation.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Main Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081F17), // Slightly lighter green box
                      border: Border.all(color: brandGreen.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                            textInputAction: TextInputAction.done,
                            onChanged: (text) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search artist...',
                              hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.3)),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(18),
                                child: Icon(Icons.search, color: Colors.white54, size: 22),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                            onSubmitted: (_) => _handleCalculate(),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'DATA SOURCES',
                          style: GoogleFonts.inter(
                            color: brandGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Platform checkboxes exactly like the image
                        _buildPlatformOption('spotify', 'Spotify', Icons.music_note, brandGreen),
                        // Youtube Middle, Apple Third
                        _buildPlatformOption('youtube', 'YouTube', Icons.play_circle_filled, const Color(0xFFef4444)),
                        _buildPlatformOption('apple', 'Apple Music', Icons.apple, Colors.white),

                        const SizedBox(height: 24),
                        
                        // Footer text
                        Text(
                          'Estimates are indicative and based on publicly available top-10 streaming data.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Calculate Button
                        GestureDetector(
                          onTap: (hasInput && !isSearching) ? _handleCalculate : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: hasInput ? brandGreen.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSearching)
                                  const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(brandGreen),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.calculate, 
                                    color: hasInput ? brandGreen : Colors.white24, 
                                    size: 20
                                  ),
                                const SizedBox(width: 12),
                                Text(
                                  isSearching ? 'Calculating...' : 'Calculate Valuation',
                                  style: GoogleFonts.inter(
                                    color: hasInput ? brandGreen : Colors.white24,
                                    fontSize: 16,
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

                // Expanding Results Section
                AnimatedCrossFade(
                  firstChild: const SizedBox(height: 40, width: double.infinity),
                  secondChild: _buildResultsSection(brandGreen, estimatedValue, artistData),
                  crossFadeState: showResults ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 600),
                  sizeCurve: Curves.easeInOut,
                ),
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

  Widget _buildResultsSection(Color brandGreen, double? estimatedValue, Map<String, dynamic>? artistData) {
    if (estimatedValue == null) return const SizedBox.shrink();
    
    final artistName = artistData?['name'] ?? _searchController.text;
    String? imageUrl;
    if (artistData != null && artistData['images'] != null && (artistData['images'] as List).isNotEmpty) {
      imageUrl = artistData['images'][0]['url'] as String?;
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
                border: Border.all(color: brandGreen.withValues(alpha: 0.3), width: 2),
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                    color: brandGreen.withValues(alpha: 0.2),
                    blurRadius: 20,
                  )
                ]
              ),
            ),
            
          Text(
            artistName as String,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'ESTIMATED CATALOG VALUE',
            style: GoogleFonts.inter(
              color: brandGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatLocalCurrency(estimatedValue),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                  border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'QUICK READ',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatQuickRead(estimatedValue),
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_getPlatformName()} @ ${_royaltyShare.toStringAsFixed(0)}% ROYALTY SHARE',
              style: GoogleFonts.inter(color: brandGreen, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2936),
              border: Border.all(color: const Color(0xFF1B4052)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.info, color: Color(0xFF38BDF8), size: 16),
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

          // Controls Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF081F17),
              border: Border.all(color: brandGreen.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Royalty share', style: GoogleFonts.inter(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF041510),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
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
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  child: Icon(Icons.add, size: 16, color: Colors.white54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _royaltyShare = 100.0;
                              _royaltyController.text = '100.0';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            decoration: BoxDecoration(
                              color: brandGreen.withValues(alpha: 0.1),
                              border: Border.all(color: brandGreen.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '100%',
                              style: GoogleFonts.inter(color: brandGreen, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Currency', style: GoogleFonts.inter(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF041510),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currency,
                          dropdownColor: const Color(0xFF081F17),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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

          const SizedBox(height: 40),

          Text(
            'Want to see the more detailed valuation report? Please login.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              try { await GoogleSignIn().signOut(); } catch(e) {}
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_search_query', _searchController.text);
              await prefs.setString('last_search_platform', _platforms.keys.firstWhere((k) => _platforms[k] == true, orElse: () => 'spotify'));
              if (mounted) {
                context.push('/login');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, color: Colors.black87, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Login to see detailed report',
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              try { await GoogleSignIn().signOut(); } catch(e) {}
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_search_query', _searchController.text);
              await prefs.setString('last_search_platform', _platforms.keys.firstWhere((k) => _platforms[k] == true, orElse: () => 'spotify'));
              if (mounted) {
                context.push('/login');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC29C5B), Color(0xFFA27A3F)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC29C5B).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
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
