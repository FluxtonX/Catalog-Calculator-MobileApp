import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_cubit.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_state.dart';
import 'package:catalog_calculator_flutter/core/utils/pdf_generator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ValuationDashboardScreen extends StatelessWidget {
  const ValuationDashboardScreen({
    required this.platform,
    required this.query,
    super.key,
  });
  final String platform;
  final String query;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchArtistCubit()..searchArtist(
        query: query,
        platforms: {
          platform: true,
          if (platform == 'spotify') 'youtube': true,
          if (platform == 'spotify') 'apple': true,
        },
      ),
      child: ValuationDashboardView(platform: platform, query: query),
    );
  }
}

class ValuationDashboardView extends StatefulWidget {
  const ValuationDashboardView({
    required this.platform,
    required this.query,
    super.key,
  });
  final String platform;
  final String query;

  @override
  State<ValuationDashboardView> createState() => _ValuationDashboardViewState();
}

class _ValuationDashboardViewState extends State<ValuationDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep Slate 950
      body: Stack(
        children: [
          // Background ambient light
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.platform == 'spotify' 
                    ? const Color(0xFF10b981).withValues(alpha: 0.05)
                    : const Color(0xFF3b82f6).withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: widget.platform == 'spotify' 
                        ? const Color(0xFF10b981).withValues(alpha: 0.1)
                        : const Color(0xFF3b82f6).withValues(alpha: 0.1), 
                    blurRadius: 100
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: BlocBuilder<SearchArtistCubit, SearchArtistState>(
              builder: (context, state) {
                if (state is SearchArtistLoading || state is SearchArtistInitial) {
                  return _buildLoadingState();
                } else if (state is SearchArtistError) {
                  return _buildErrorState(state.message);
                } else if (state is SearchArtistLoaded) {
                  return _buildDashboard(state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF10b981)),
          const SizedBox(height: 24),
          Text(
            'Analyzing Catalog...',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching real-time metrics for ${widget.query}',
            style: GoogleFonts.inter(
              color: const Color(0xFF94a3b8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.redAccent.shade100, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Text('Go Back'),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(SearchArtistLoaded state) {
    final artistData = state.artistData;
    final valuationData = state.valuationData;
    final estimatedValue = state.estimatedValue;
    final youtubeData = state.youtubeData;
    final appleData = state.appleData;
    
    final artistName = (artistData['name'] as String?) ?? widget.query;
    String? imageUrl;
    if (artistData['images'] != null && (artistData['images'] as List).isNotEmpty) {
      imageUrl = ((artistData['images'] as List)[0] as Map)['url'] as String?;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Back button, Export, and Logout)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                onPressed: () => context.pop(),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  PdfGenerator.generateAndShareValuationReport(
                    artistName: artistName,
                    estimatedValue: estimatedValue,
                    platform: widget.platform,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981).withValues(alpha: 0.2),
                  foregroundColor: const Color(0xFF10b981),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (Supabase.instance.client.auth.currentSession != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      context.go('/search');
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        
        // Artist Header Profile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                  image: imageUrl != null 
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: imageUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artistName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.platform == 'spotify' 
                            ? const Color(0xFF10b981).withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.platform.toUpperCase()} CATALOG',
                        style: GoogleFonts.inter(
                          color: widget.platform == 'spotify' 
                              ? const Color(0xFF34d399)
                              : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // TabBar
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF10b981),
          labelColor: const Color(0xFF10b981),
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Spotify'),
            Tab(text: 'Apple Music'),
            Tab(text: 'YouTube'),
          ],
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(estimatedValue, valuationData),
              _buildSpotifyTab(artistData, valuationData),
              _buildAppleTab(appleData, valuationData),
              _buildYouTubeTab(youtubeData, valuationData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(double estimatedValue, Map<String, dynamic> valuationData) {
    final streamingRevenue = (valuationData['streamingRevenue'] as num?)?.toDouble() ?? 0.0;
    final publishingRevenue = (valuationData['publishingRevenue'] as num?)?.toDouble() ?? 0.0;
    final combinedRevenue = streamingRevenue + publishingRevenue;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10b981), Color(0xFF047857)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10b981).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'EST. CATALOG VALUATION',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatCurrency(estimatedValue),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Est. Monthly Rev',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(combinedRevenue / 12),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Market Multiple',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3.0x',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Premium Analytics Unlocked',
            style: GoogleFonts.outfit(
              color: const Color(0xFF10b981),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Streaming Revenue', style: GoogleFonts.inter(color: Colors.white70)),
                    Text(_formatCurrency(streamingRevenue), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: Colors.white24, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Publishing/Sync', style: GoogleFonts.inter(color: Colors.white70)),
                    Text(_formatCurrency(publishingRevenue), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: Colors.white24, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Projected Growth (YoY)', style: GoogleFonts.inter(color: Colors.white70)),
                    Text('+14.2%', style: GoogleFonts.inter(color: const Color(0xFF10b981), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifyTab(Map<String, dynamic> spotifyData, Map<String, dynamic> valuationData) {
    Map<String, dynamic>? followersMap;
    if (spotifyData['followers'] is Map) {
      followersMap = spotifyData['followers'] as Map<String, dynamic>?;
    }
    final followers = (followersMap?['total'] as num?)?.toInt() ?? 0;
    final popularity = (spotifyData['popularity'] as num?)?.toInt() ?? 0;
    
    Map<String, dynamic>? platformValuation;
    final valData = valuationData['breakdown']?['spotify'] ?? valuationData['breakdown']?['apify'];
    if (valData is Map) {
      platformValuation = valData as Map<String, dynamic>?;
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (platformValuation != null)
            _buildPlatformValuationCard(
              title: 'Spotify CFA Valuation',
              color: const Color(0xFF1DB954),
              valuation: platformValuation,
            ),
          const SizedBox(height: 24),
          _buildStatCard(
            title: 'Spotify Catalog Stats',
            icon: Icons.graphic_eq,
            color: const Color(0xFF1DB954),
            stats: {
              'Followers': _formatNumber(followers.toDouble()),
              'Popularity': '$popularity/100',
              'Est. Reach': _formatNumber(followers * 1.5),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppleTab(Map<String, dynamic>? appleData, Map<String, dynamic> valuationData) {
    if (appleData == null) {
      return Center(
        child: Text('Apple Music data not found.', style: GoogleFonts.inter(color: Colors.white70)),
      );
    }
    
    Map<String, dynamic>? platformValuation;
    final valData = valuationData['breakdown']?['itunes'] ?? valuationData['breakdown']?['apple'];
    if (valData is Map) {
      platformValuation = valData as Map<String, dynamic>?;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (platformValuation != null)
            _buildPlatformValuationCard(
              title: 'Apple Music CFA Valuation',
              color: const Color(0xFFFA243C),
              valuation: platformValuation,
            ),
          const SizedBox(height: 24),
          _buildStatCard(
            title: 'Apple Music Catalog Stats',
            icon: Icons.music_note,
            color: const Color(0xFFFA243C),
            stats: {
              'Status': 'Available',
              'ID': appleData['id']?.toString() ?? 'N/A',
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeTab(Map<String, dynamic>? youtubeData, Map<String, dynamic> valuationData) {
    if (youtubeData == null) {
      return Center(
        child: Text('YouTube data not requested.', style: GoogleFonts.inter(color: Colors.white70)),
      );
    }
    
    int subs = 0;
    int views = 0;
    int videos = 0;
    
    if (youtubeData['channels'] != null && (youtubeData['channels'] as List).isNotEmpty) {
      final stats = ((youtubeData['channels'] as List)[0] as Map)['statistics'] as Map?;
      if (stats != null) {
        subs = int.tryParse(stats['subscriberCount']?.toString() ?? '0') ?? 0;
        views = int.tryParse(stats['viewCount']?.toString() ?? '0') ?? 0;
        videos = int.tryParse(stats['videoCount']?.toString() ?? '0') ?? 0;
      }
    }

    Map<String, dynamic>? platformValuation;
    final valData = valuationData['breakdown']?['youtube'];
    if (valData is Map) {
      platformValuation = valData as Map<String, dynamic>?;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (platformValuation != null)
            _buildPlatformValuationCard(
              title: 'YouTube CFA Valuation',
              color: const Color(0xFFFF0000),
              valuation: platformValuation,
            ),
          const SizedBox(height: 24),
          _buildStatCard(
            title: 'YouTube Channel Stats',
            icon: Icons.smart_display,
            color: const Color(0xFFFF0000),
            stats: {
              'Subscribers': _formatNumber(subs.toDouble()),
              'Total Views': _formatNumber(views.toDouble()),
              'Videos': _formatNumber(videos.toDouble()),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformValuationCard({required String title, required Color color, required Map<String, dynamic> valuation}) {
    final midEstimate = (valuation['midEstimate'] as num?)?.toDouble() ?? 0;
    final annualRevenue = (valuation['totalAnnualRevenue'] as num?)?.toDouble() ?? 0;
    final averageAge = (valuation['averageDollarAge'] as num?)?.toDouble() ?? 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(midEstimate),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Est. Annual Rev', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(annualRevenue), style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Avg. Catalog Age', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${averageAge.toStringAsFixed(1)} Years', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }

  Widget _buildStatCard({required String title, required IconData icon, required Color color, required Map<String, String> stats}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.entries.map((e) => Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(e.value, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
