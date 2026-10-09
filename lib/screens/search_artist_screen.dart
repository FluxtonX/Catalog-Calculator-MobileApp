import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchArtistScreen extends StatefulWidget {
  const SearchArtistScreen({super.key});

  @override
  State<SearchArtistScreen> createState() => _SearchArtistScreenState();
}

class _SearchArtistScreenState extends State<SearchArtistScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _royaltyController = TextEditingController(text: '100');
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
  double _royaltyShare = 100.0;

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
    if (upper.contains("B")) return double.parse(upper.replaceAll("B", "")) * 1e9;
    if (upper.contains("M")) return double.parse(upper.replaceAll("M", "")) * 1e6;
    if (upper.contains("K")) return double.parse(upper.replaceAll("K", "")) * 1e3;
    return double.tryParse(upper.replaceAll(RegExp(r','), '')) ?? 0;
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
      List<String> platformsToFetch = [];
      if (_platforms['spotify'] == true) platformsToFetch.add('apify');
      if (_platforms['apple'] == true) platformsToFetch.add('itunes');
      if (_platforms['youtube'] == true) platformsToFetch.add('youtube');
      
      // CRITICAL - The Proxy Rule
      if (_platforms['apple'] == true && _platforms['spotify'] != true) {
        platformsToFetch.add('apify_proxy'); 
      }

      Map<String, Map<String, dynamic>> artistsMap = {};

      List<Future<void>> futures = platformsToFetch.map((fetchKey) async {
        try {
          String functionName = fetchKey == 'apify_proxy' ? 'apify' : fetchKey;
          Map<String, dynamic> requestBody = {'query': query};
          if (fetchKey == 'itunes') {
            requestBody['useMusicKit'] = true;
          }

          var response = await Supabase.instance.client.functions.invoke(
            functionName,
            body: requestBody,
          );

          if (fetchKey == 'itunes' && (response.data == null || (response.data is Map && response.data['error'] != null))) {
            requestBody['useMusicKit'] = false;
            response = await Supabase.instance.client.functions.invoke(
              functionName,
              body: requestBody,
            );
          }

          var data = response.data;
          
          if (fetchKey == 'youtube' && (data == null || data['error'] != null || (data is Map && !data.containsKey('channels')))) {
            try {
              // Client-side fallback identical to web app's api.js
              String apiKey = 'AIzaSyBvlzgXH5IKpLZFckQu-_KXv_rdMELAdNw';
              var httpClient = HttpClient();
              var req1 = await httpClient.getUrl(Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&type=channel&q=${Uri.encodeComponent(query)}&maxResults=1&key=$apiKey'));
              var res1 = await req1.close();
              var body1 = await res1.transform(utf8.decoder).join();
              var json1 = jsonDecode(body1);
              
              if (json1['items'] != null && (json1['items'] as List).isNotEmpty) {
                String channelId = json1['items'][0]['id']['channelId'] ?? json1['items'][0]['id'];
                
                var req2 = await httpClient.getUrl(Uri.parse('https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet&id=$channelId&key=$apiKey'));
                var res2 = await req2.close();
                var body2 = await res2.transform(utf8.decoder).join();
                var json2 = jsonDecode(body2);
                
                if (json2['items'] != null && (json2['items'] as List).isNotEmpty) {
                  var item = json2['items'][0];
                  data = {
                    'platform': 'youtube',
                    'title': item['snippet']['title'],
                    'channelTitle': item['snippet']['title'],
                    'subscribers': int.tryParse(item['statistics']['subscriberCount']?.toString() ?? '0') ?? 0,
                    'totalViews': int.tryParse(item['statistics']['viewCount']?.toString() ?? '0') ?? 0,
                    'tracksCount': int.tryParse(item['statistics']['videoCount']?.toString() ?? '0') ?? 0,
                  };
                }
              }
            } catch (fallbackErr) {
              print('YouTube direct fallback failed: $fallbackErr');
            }
          } else if (fetchKey == 'youtube' && data != null && data is Map) {
            String? channelId;
            if (data['channels'] != null && (data['channels'] as List).isNotEmpty) {
              channelId = data['channels'][0]['id'];
            } else if (data['channel'] != null) {
              channelId = data['channel']['id'];
            }
            
            if (channelId != null) {
              final detailsResponse = await Supabase.instance.client.functions.invoke(
                'youtube',
                body: {'query': query, 'channelId': channelId},
              );
              data = detailsResponse.data;
            }
          }

          Map<String, dynamic>? artistData;
          if (data != null && data is Map<String, dynamic> && (data.containsKey('name') || data.containsKey('title') || data.containsKey('channelTitle') || data.containsKey('platform'))) {
            artistData = data;
          } else if (data != null && data['artists'] != null) {
             final artistsData = data['artists'];
             if (artistsData is Map && artistsData['items'] != null && (artistsData['items'] as List).isNotEmpty) {
                artistData = artistsData['items'][0];
             }
          } else if (data != null && data['results'] != null && (data['results'] as List).isNotEmpty) {
             artistData = data['results'][0];
          } else if (data != null && data is Map<String, dynamic>) {
             // Fallback: just use the raw map if it seems like a valid object
             artistData = data;
          }

          if (artistData != null) {
            String mapKey = fetchKey == 'apify' ? 'spotify' : (fetchKey == 'apify_proxy' ? 'spotify_proxy' : fetchKey);
            artistsMap[mapKey] = Map<String, dynamic>.from(artistData)..['platform'] = mapKey;
          }
        } catch (e) {
          print('Failed to fetch $fetchKey: $e');
          if (fetchKey == 'itunes') {
            try {
              final fallbackResponse = await Supabase.instance.client.functions.invoke(
                'itunes',
                body: {'query': query, 'useMusicKit': false},
              );
              final data = fallbackResponse.data;
              Map<String, dynamic>? artistData;
              if (data != null && data is Map<String, dynamic> && (data.containsKey('name') || data.containsKey('title') || data.containsKey('channelTitle') || data.containsKey('platform'))) {
                artistData = data;
              } else if (data != null && data['artists'] != null) {
                 final artistsData = data['artists'];
                 if (artistsData is Map && artistsData['items'] != null && (artistsData['items'] as List).isNotEmpty) {
                    artistData = artistsData['items'][0];
                 }
              } else if (data != null && data['results'] != null && (data['results'] as List).isNotEmpty) {
                 artistData = data['results'][0];
              } else if (data != null && data is Map<String, dynamic>) {
                 artistData = data;
              }
              if (artistData != null) {
                artistsMap['itunes'] = Map<String, dynamic>.from(artistData)..['platform'] = 'itunes';
              }
            } catch (fallbackError) {
              print('Fallback failed for itunes: $fallbackError');
            }
          }
        }
      }).toList();

      await Future.wait(futures);

      if (artistsMap.isEmpty) {
        throw Exception("Could not find catalog data for this artist on any selected platform.");
      }
      
      _artistData = artistsMap['spotify'] ?? artistsMap['spotify_proxy'] ?? artistsMap['itunes'] ?? artistsMap['youtube'] ?? artistsMap.values.first;

      final calculateResponse = await Supabase.instance.client.functions.invoke(
        'calculate-valuation',
        body: {'artistsMap': artistsMap},
      );

      final finalData = calculateResponse.data;
      if (finalData == null || finalData['midEstimate'] == null) {
        throw Exception("Valuation engine returned invalid data.");
      }

      setState(() => _estimatedValue = (finalData['midEstimate'] as num).toDouble());
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
    
    final Map<String, String> currencySymbols = {
      'USD': '\$',
      'GBP': '£',
      'EUR': '€',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'CHF': 'CHF',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'ZAR': 'R',
      'BRL': 'R\$',
      'MXN': '\$',
      'NZD': 'NZ\$',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'SGD': 'S\$',
      'HKD': 'HK\$',
    };
    
    String symbol = currencySymbols[_currency] ?? '\$';
    
    String numStr = converted.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    
    return '$symbol$numStr';
  }

  String _formatQuickRead(double value) {
    double adjustedValue = value * (_royaltyShare / 100);
    double rate = _exchangeRates[_currency] ?? 1.0;
    double converted = adjustedValue * rate;
    
    final Map<String, String> currencySymbols = {
      'USD': '\$', 'GBP': '£', 'EUR': '€', 'AUD': 'A\$', 'CAD': 'C\$', 
      'CHF': 'CHF', 'JPY': '¥', 'CNY': '¥', 'INR': '₹', 'ZAR': 'R', 
      'BRL': 'R\$', 'MXN': '\$', 'NZD': 'NZ\$', 'SEK': 'kr', 
      'NOK': 'kr', 'DKK': 'kr', 'SGD': 'S\$', 'HKD': 'HK\$',
    };
    String symbol = currencySymbols[_currency] ?? '\$';
    
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
                        color: brandGreen.withValues(alpha: 0.1),
                        border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
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
                    color: brandGreen.withValues(alpha: 0.1),
                    border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
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
                            color: Colors.white.withValues(alpha: 0.4),
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
                              color: hasInput ? brandGreen.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
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

  String _getPlatformName() {
    List<String> selected = [];
    if (_platforms['spotify'] == true) selected.add('SPOTIFY');
    if (_platforms['apple'] == true) selected.add('APPLE MUSIC');
    if (_platforms['youtube'] == true) selected.add('YOUTUBE');
    
    if (selected.length == 3) return "ALL PLATFORMS";
    return selected.join(" & ");
  }

  String _getNoteText() {
    int count = _platforms.values.where((v) => v).length;
    if (count == 1) {
      String name = _platforms.keys.firstWhere((k) => _platforms[k] == true);
      name = name == 'apple' ? 'Apple Music' : (name == 'youtube' ? 'YouTube' : 'Spotify');
      return 'Note: This is your catalog valuation calculated for $name only.';
    }
    return 'Note: This is your catalog valuation calculated across combined platforms.';
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
                _formatQuickRead(_estimatedValue!),
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
                                      double? parsed = double.tryParse(value);
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
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _currency = newValue);
                            }
                          },
                          items: _exchangeRates.keys.toList()
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
