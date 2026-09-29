import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchArtistScreen extends StatefulWidget {
  const SearchArtistScreen({super.key});

  @override
  State<SearchArtistScreen> createState() => _SearchArtistScreenState();
}

class _SearchArtistScreenState extends State<SearchArtistScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isSearching = false;
  String? _errorMessage;
  double? _estimatedValue;
  Map<String, dynamic>? _artistData;

  // Multiple Platform Selection
  final Map<String, bool> _platforms = {
    'spotify': true,
    'youtube': true,
    'apple': true,
  };

  // Results Options State
  String _currency = 'USD';
  int _royaltyShare = 100;

  final Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'GBP': 0.79,
    'EUR': 0.92,
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

  Future<void> _handleCalculate([String? overrideQuery]) async {
    final query = (overrideQuery ?? _searchController.text).trim();
    if (query.isEmpty) return;
    
    if (overrideQuery != null && _searchController.text != overrideQuery) {
      _searchController.text = overrideQuery;
    }

    if (!_platforms.values.any((isSelected) => isSelected)) {
      setState(() => _errorMessage = "Please select at least one data source.");
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _estimatedValue = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'apify',
        body: {'query': query},
      );

      final data = response.data;
      if (data != null && data is Map<String, dynamic> && data.containsKey('name')) {
        _artistData = data;
      } else if (data != null && data['artists'] != null) {
         final artistsData = data['artists'];
         if (artistsData is Map && artistsData['items'] != null && (artistsData['items'] as List).isNotEmpty) {
            _artistData = artistsData['items'][0];
         }
      }

      if (_artistData == null) {
        throw Exception("Could not find catalog data for this artist.");
      }

      double listeners = 0;
      if (_artistData!['stats'] != null && _artistData!['stats']['monthlyListeners'] != null) {
        listeners = double.tryParse(_artistData!['stats']['monthlyListeners'].toString()) ?? 0;
      } else if (_artistData!['followers'] != null && _artistData!['followers']['total'] != null) {
        listeners = (_artistData!['followers']['total'] as num).toDouble() * 1.5; 
      }
      
      double estimatedMonthlyStreams = listeners * 5;
      double monthlyRevenue = estimatedMonthlyStreams * 0.003;
      double catalogValue = monthlyRevenue * 12 * 3; // LTM * 3x multiple
      
      if (catalogValue == 0) catalogValue = 250000;

      setState(() => _estimatedValue = catalogValue);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  String _formatLocalCurrency(double value) {
    double adjustedValue = value * (_royaltyShare / 100);
    double rate = _exchangeRates[_currency] ?? 1.0;
    double converted = adjustedValue * rate;
    
    String symbol = '\$';
    if (_currency == 'GBP') symbol = '£';
    if (_currency == 'EUR') symbol = '€';
    
    String numStr = converted.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    
    return '$symbol$numStr';
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
          color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.5) : Colors.white.withOpacity(0.15),
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
                color: isSelected ? activeColor : Colors.white.withOpacity(0.1),
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
    final bool showResults = _estimatedValue != null;
    final bool hasInput = _searchController.text.trim().isNotEmpty;
    
    // Very dark emerald background color matching the image
    const Color bgColor = Color(0xFF041510);
    const Color brandGreen = Color(0xFF34d399); // Bright green
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        color: brandGreen.withOpacity(0.1),
                        border: Border.all(color: brandGreen.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.bar_chart, color: brandGreen, size: 16),
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
                    color: brandGreen.withOpacity(0.1),
                    border: Border.all(color: brandGreen.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: brandGreen, size: 14),
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
                    text: 'What\'s Your\n',
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
                      color: Colors.white.withOpacity(0.6),
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
                      border: Border.all(color: brandGreen.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                            textInputAction: TextInputAction.done,
                            onChanged: (text) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search artist...',
                              hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.3)),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(18.0),
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
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Calculate Button
                        GestureDetector(
                          onTap: (hasInput && !_isSearching) ? _handleCalculate : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: hasInput ? brandGreen.withOpacity(0.15) : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isSearching)
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
                                  _isSearching ? 'Calculating...' : 'Calculate Valuation',
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

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.red.shade400, fontSize: 14),
                    ),
                  ),

                // Expanding Results Section
                AnimatedCrossFade(
                  firstChild: const SizedBox(height: 40, width: double.infinity),
                  secondChild: _buildResultsSection(brandGreen),
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
  }

  Widget _buildResultsSection(Color brandGreen) {
    if (_estimatedValue == null) return const SizedBox.shrink();
    
    final artistName = _artistData?['name'] ?? _searchController.text;
    String? imageUrl;
    if (_artistData != null && _artistData!['images'] != null && (_artistData!['images'] as List).isNotEmpty) {
      imageUrl = _artistData!['images'][0]['url'];
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
                border: Border.all(color: brandGreen.withOpacity(0.3), width: 2),
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                    color: brandGreen.withOpacity(0.2),
                    blurRadius: 20,
                  )
                ]
              ),
            ),
            
          Text(
            artistName,
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
            _formatLocalCurrency(_estimatedValue!),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          
          const SizedBox(height: 32),

          // Controls Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF081F17),
              border: Border.all(color: brandGreen.withOpacity(0.15)),
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
                          width: 80,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF041510),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$_royaltyShare', style: GoogleFonts.inter(color: Colors.white, fontSize: 15)),
                              Text('%', style: GoogleFonts.inter(color: Colors.white30, fontSize: 15)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _royaltyShare = 100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: brandGreen.withOpacity(0.1),
                              border: Border.all(color: brandGreen.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '100%',
                              style: GoogleFonts.inter(color: brandGreen, fontSize: 14, fontWeight: FontWeight.bold),
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
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currency,
                          dropdownColor: const Color(0xFF081F17),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.5)),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _currency = newValue);
                            }
                          },
                          items: <String>['USD', 'GBP', 'EUR']
                              .map<DropdownMenuItem<String>>((String value) {
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
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              context.push('/login');
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
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    height: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Login with Google',
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC29C5B), Color(0xFFA27A3F)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC29C5B).withOpacity(0.3),
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
          )
        ],
      ),
    );
  }
}
