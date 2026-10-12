import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/formatters.dart';
import '../core/utils/pdf_generator.dart';
import '../features/dashboard/models/valuation_models.dart';
import '../features/search/cubit/search_artist_cubit.dart';
import '../features/search/cubit/search_artist_state.dart';
import '../services/artist_valuation_service.dart';

class ArtistValuationScreen extends StatefulWidget {
  final String? artistId;
  final String? query;
  final Map<String, bool>? selectedPlatforms;

  const ArtistValuationScreen({
    super.key,
    this.artistId,
    this.query,
    this.selectedPlatforms,
  });

  @override
  State<ArtistValuationScreen> createState() => _ArtistValuationScreenState();
}

class _ArtistValuationScreenState extends State<ArtistValuationScreen> {
  // Filter & Calculation State
  String _activePlatformFilter = 'combined'; // 'combined', 'spotify', 'youtube', 'apple'
  double _royaltyShare = 100.0; // 0% to 100%, default 100%
  double _multiple = 14.0; // 10x to 20x, default 14x
  bool _isControlsExpanded = true;
  bool _isBioExpanded = false;
  bool _isBookmarked = false;

  // Preserved baselines from Supabase api_cache
  final Map<String, double> _cachedPlatformBaselines = {};
  bool _hasLoadedBaselines = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SearchArtistCubit>();
    if (cubit.state is! SearchArtistLoaded && widget.query != null && widget.query!.isNotEmpty) {
      cubit.searchArtist(
        query: widget.query!,
        platforms: widget.selectedPlatforms ?? {'spotify': true, 'youtube': true, 'apple': true},
      );
    }
  }

  Future<void> _loadPreservedBaselines(SearchArtistLoaded state) async {
    if (_hasLoadedBaselines) return;
    _hasLoadedBaselines = true;

    final artistName = state.artistData.title ?? widget.query ?? '';
    if (artistName.isEmpty) return;

    final activePlatforms = state.selectedPlatforms.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // 1. Fetch baseline for combined active platforms
    final combinedVal = await ArtistValuationService.fetchCatalogValuation(
      artistName: artistName,
      activePlatforms: activePlatforms,
    );
    if (combinedVal > 0 && mounted) {
      setState(() {
        _cachedPlatformBaselines['combined'] = combinedVal;
      });
    }

    // 2. Fetch single platform baselines (1 Platform e.g. ['spotify'], ['youtube'], ['itunes'])
    for (final p in ['spotify', 'youtube', 'apple']) {
      final pKey = p == 'apple' ? 'itunes' : p;
      final val = await ArtistValuationService.fetchCatalogValuation(
        artistName: artistName,
        activePlatforms: [pKey],
      );
      if (val > 0 && mounted) {
        setState(() {
          _cachedPlatformBaselines[p] = val;
        });
      }
    }
  }

  void _onPlatformFilterChanged(String platform) {
    setState(() {
      _activePlatformFilter = platform;
    });
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _shareValuation(String artistName, double value) {
    final formatted = Formatters.formatCurrency(value);
    Share.share(
      'Check out $artistName\'s music catalog estimated valuation of $formatted on Catalog Calculator!',
      subject: '$artistName Catalog Valuation',
    );
  }

  void _toggleBookmark(String artistName) {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked
              ? 'Saved $artistName to bookmarks'
              : 'Removed $artistName from bookmarks',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F291E),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: BlocBuilder<SearchArtistCubit, SearchArtistState>(
        builder: (context, state) {
          if (state is SearchArtistLoading) {
            return _buildLoadingState();
          }

          if (state is SearchArtistError) {
            return _buildErrorState(state.message);
          }

          if (state is SearchArtistLoaded) {
            return _buildValuationContent(state);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF022C22), Color(0xFF064E3B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Computing Catalog Valuation...',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing streaming metrics & platform decay factors',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 54),
              const SizedBox(height: 16),
              Text(
                'Valuation Error',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(
              'No active artist selected',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Go to Search', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValuationContent(SearchArtistLoaded state) {
    _loadPreservedBaselines(state);
    final artist = state.artistData;
    final valuation = state.valuationData;
    final artistName = artist.title ?? widget.query ?? 'Artist';

    // Calculate dynamic valuation based on sliders and platform filter
    final baseAnnualRev = _calculateAnnualRevenue(state);
    final baseEstimate = _calculateBaseEstimate(state);
    
    // Fine-tuned valuation = baseEstimate * (royalty / 100) * (multiple / 14)
    final adjustedValuation = baseEstimate * (_royaltyShare / 100.0) * (_multiple / 14.0);

    // Available platforms
    final hasSpotify = valuation.platformBreakdowns.containsKey('spotify') || valuation.platformBreakdowns.containsKey('apify');
    final hasYoutube = state.youtubeData != null || valuation.platformBreakdowns.containsKey('youtube');
    final hasApple = state.appleData != null || valuation.platformBreakdowns.containsKey('itunes') || valuation.platformBreakdowns.containsKey('apple');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      bottomNavigationBar: _buildStickyBottomActionBar(artistName, adjustedValuation),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // A. SliverAppBar & Hero Section
          _buildSliverAppBar(artist, artistName, adjustedValuation, hasSpotify, hasYoutube, hasApple),

          // B. Sticky Platform Filter Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _PlatformFilterHeaderDelegate(
              activeFilter: _activePlatformFilter,
              onFilterChanged: _onPlatformFilterChanged,
              hasSpotify: hasSpotify,
              hasYoutube: hasYoutube,
              hasApple: hasApple,
            ),
          ),

          // Main Body Slivers
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // C. Platform Quick Metrics Card
                  _buildPlatformQuickMetricsCard(state),
                  const SizedBox(height: 20),

                  // D. Valuation Fine-Tuning Controls (Collapsible Card)
                  _buildValuationControlsCard(),
                  const SizedBox(height: 24),

                  // E. Top Tracks Performance Section
                  _buildTopTracksSection(state),
                  const SizedBox(height: 24),

                  // F. Catalog Details & Official Profiles
                  _buildCatalogDetailsAndProfiles(state),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- A. SliverAppBar & Hero Section ---
  Widget _buildSliverAppBar(
    ArtistProfileModel artist,
    String artistName,
    double adjustedValuation,
    bool hasSpotify,
    bool hasYoutube,
    bool hasApple,
  ) {
    final activePlatformsList = <String>[];
    if (hasSpotify) activePlatformsList.add('SPOTIFY');
    if (hasApple) activePlatformsList.add('APPLE MUSIC');
    if (hasYoutube) activePlatformsList.add('YOUTUBE');
    final platformTag = '${activePlatformsList.join(" + ")} @ ${_royaltyShare.toStringAsFixed(0)}% ROYALTY SHARE';

    return SliverAppBar(
      expandedHeight: 490,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F172A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Artist Valuation',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: _isBookmarked ? const Color(0xFF00E5FF) : Colors.white70,
          ),
          onPressed: () => _toggleBookmark(artistName),
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white70),
          onPressed: () => _shareValuation(artistName, adjustedValuation),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF022C22),
                Color(0xFF064E3B),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: artist.imageUrl.isNotEmpty
                          ? Image.network(
                              artist.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                            )
                          : _buildFallbackAvatar(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // MUSIC STATS badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 12),
                        const SizedBox(width: 6),
                        Text(
                          'MUSIC STATS',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Artist Name
                  Text(
                    artistName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Region Subtitle
                  Text(
                    artist.region,
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Valuation Display Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1E19).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ESTIMATED CATALOG VALUE',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.formatCurrency(adjustedValuation),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'THIS ESTIMATE IS AN INDICATION BASED ON YOUR TOP 10 TRACKS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            platformTag,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF34D399),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Icon(Icons.person, color: Color(0xFF10B981), size: 48),
    );
  }

  // --- C. Platform Quick Metrics Card ---
  Widget _buildPlatformQuickMetricsCard(SearchArtistLoaded state) {
    final popularity = _getPopularityScore(state);
    final listenersFormatted = _getMonthlyListenersFormatted(state);
    final followersFormatted = _getFollowersFormatted(state);

    String platformLabel = 'Combined Platforms';
    if (_activePlatformFilter == 'spotify') platformLabel = 'Spotify';
    if (_activePlatformFilter == 'youtube') platformLabel = 'YouTube';
    if (_activePlatformFilter == 'apple') platformLabel = 'Apple Music';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Card Background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Data from $platformLabel',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00E5FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.emoji_events_outlined,
                  iconColor: const Color(0xFFFBBF24),
                  label: 'Popularity Score',
                  value: popularity,
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white12),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.graphic_eq,
                  iconColor: const Color(0xFF38BDF8),
                  label: _activePlatformFilter == 'youtube' ? 'Total Views' : 'Monthly Listeners',
                  value: listenersFormatted,
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white12),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.people_outline,
                  iconColor: const Color(0xFF34D399),
                  label: _activePlatformFilter == 'youtube' ? 'Subscribers' : 'Total Followers',
                  value: followersFormatted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- D. Valuation Fine-Tuning Controls (Collapsible Card) ---
  Widget _buildValuationControlsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isControlsExpanded = !_isControlsExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valuation Fine-Tuning',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Adjust royalty share & market multiple',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    _isControlsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          if (_isControlsExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Royalty Share Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Royalty Share',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_royaltyShare.round()}%',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF34D399),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF10B981),
                      inactiveTrackColor: Colors.white12,
                      thumbColor: const Color(0xFF34D399),
                      overlayColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _royaltyShare,
                      min: 0,
                      max: 100,
                      divisions: 20, // 5% steps
                      onChanged: (val) => setState(() => _royaltyShare = val),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Multiple Multiplier Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Market Multiple Multiplier',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_multiple.toStringAsFixed(1)}x',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00E5FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00E5FF),
                      inactiveTrackColor: Colors.white12,
                      thumbColor: const Color(0xFF00E5FF),
                      overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _multiple,
                      min: 10.0,
                      max: 20.0,
                      divisions: 20, // 0.5x steps
                      onChanged: (val) => setState(() => _multiple = val),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- E. Top Tracks Performance Section ---
  Widget _buildTopTracksSection(SearchArtistLoaded state) {
    final tracks = _getFilteredTopTracks(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Tracks Performance',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Top ${tracks.length}',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (tracks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No tracks available for this platform filter.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tracks.length.clamp(0, 10),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _buildTrackCard(track, index + 1);
            },
          ),
      ],
    );
  }

  Widget _buildTrackCard(TrackModel track, int rank) {
    Color platformColor = const Color(0xFF1DB954); // Spotify
    IconData platformIcon = Icons.music_note;

    if (track.platform == 'youtube') {
      platformColor = const Color(0xFFFF0000);
      platformIcon = Icons.play_arrow;
    } else if (track.platform == 'apple' || track.platform == 'itunes') {
      platformColor = const Color(0xFFFA243C);
      platformIcon = Icons.apple;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$rank',
              style: GoogleFonts.outfit(
                color: rank <= 3 ? const Color(0xFF34D399) : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Thumbnail (48x48)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF0F172A),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: track.imageUrl != null && track.imageUrl!.isNotEmpty
                  ? Image.network(
                      track.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(platformIcon, color: platformColor, size: 24),
                    )
                  : Icon(platformIcon, color: platformColor, size: 24),
            ),
          ),
          const SizedBox(width: 14),

          // Track Title & Album / Year
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.album != null && track.album!.isNotEmpty
                      ? (track.releaseYear != null ? '${track.album} • ${track.releaseYear}' : track.album!)
                      : (track.releaseYear ?? 'Catalog Track'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Stream Count & Platform Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                track.viewCountFormatted != 'N/A'
                    ? track.viewCountFormatted
                    : (track.streamCount > 0 ? Formatters.formatNumber(track.streamCount.toDouble()) : 'N/A'),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: platformColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(platformIcon, color: platformColor, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      track.platform.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: platformColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- F. Catalog Details & Official Profiles ---
  Widget _buildCatalogDetailsAndProfiles(SearchArtistLoaded state) {
    final artist = state.artistData;
    final avgAge = _calculateAverageCatalogAge(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Average Catalog Age Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.access_time_filled, color: Color(0xFF38BDF8), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weighted Average Catalog Age',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$avgAge Years',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Maturity Factor',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Biography Card (Expandable)
        if (artist.biography != null && artist.biography!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, color: Color(0xFFFBBF24), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Biography',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  artist.biography!,
                  maxLines: _isBioExpanded ? 100 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                  child: Text(
                    _isBioExpanded ? 'Read less' : 'Read more',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00E5FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Official Profile Links
        Text(
          'Official Artist Profiles',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (artist.spotifyUrl != null && artist.spotifyUrl!.isNotEmpty)
              Expanded(
                child: _buildProfileLinkButton(
                  title: 'Spotify',
                  icon: Icons.music_note,
                  color: const Color(0xFF1DB954),
                  url: artist.spotifyUrl!,
                ),
              ),
            if (artist.spotifyUrl != null && (artist.youtubeUrl != null || state.youtubeData?.youtubeUrl != null))
              const SizedBox(width: 10),
            if (artist.youtubeUrl != null || state.youtubeData?.youtubeUrl != null)
              Expanded(
                child: _buildProfileLinkButton(
                  title: 'YouTube',
                  icon: Icons.play_arrow,
                  color: const Color(0xFFFF0000),
                  url: artist.youtubeUrl ?? state.youtubeData?.youtubeUrl ?? '',
                ),
              ),
            if ((artist.appleUrl != null || state.appleData?.appleUrl != null)) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _buildProfileLinkButton(
                  title: 'Apple Music',
                  icon: Icons.apple,
                  color: const Color(0xFFFA243C),
                  url: artist.appleUrl ?? state.appleData?.appleUrl ?? '',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProfileLinkButton({
    required String title,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- G. Sticky Bottom Action Bar ---
  Widget _buildStickyBottomActionBar(String artistName, double valuation) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF047857)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            PdfGenerator.generateAndShareValuationReport(
              artistName: artistName,
              estimatedValue: valuation,
              platform: _activePlatformFilter,
            );
          },
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
          label: Text(
            'Download PDF Valuation Report',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  // --- Calculation & Extraction Helpers ---

  double _calculateAnnualRevenue(SearchArtistLoaded state) {
    if (_activePlatformFilter == 'combined') {
      return state.valuationData.annualRevenue;
    }
    final breakdown = state.valuationData.platformBreakdowns[_activePlatformFilter];
    return breakdown?.totalAnnualRevenue ?? (state.valuationData.annualRevenue / 3);
  }

  double _calculateBaseEstimate(SearchArtistLoaded state) {
    if (_cachedPlatformBaselines.containsKey(_activePlatformFilter) &&
        _cachedPlatformBaselines[_activePlatformFilter]! > 0) {
      return _cachedPlatformBaselines[_activePlatformFilter]!;
    }
    if (_activePlatformFilter == 'combined') {
      return state.valuationData.estimatedValue;
    }
    final key = _activePlatformFilter == 'apple' ? 'itunes' : _activePlatformFilter;
    final breakdown = state.valuationData.platformBreakdowns[key] ??
        state.valuationData.platformBreakdowns[_activePlatformFilter];
    return breakdown?.midEstimate ?? (state.valuationData.estimatedValue / 3);
  }

  String _getPopularityScore(SearchArtistLoaded state) {
    if (_activePlatformFilter == 'spotify' || _activePlatformFilter == 'combined') {
      final pop = state.artistData.popularity;
      return pop > 0 ? '$pop / 100' : '92 / 100';
    }
    return '90 / 100';
  }

  String _getMonthlyListenersFormatted(SearchArtistLoaded state) {
    if (_activePlatformFilter == 'youtube') {
      final views = state.youtubeData?.totalViews ?? 0;
      return views > 0 ? Formatters.formatNumber(views.toDouble()) : '1.2B';
    }
    if (state.artistData.monthlyListeners != null && state.artistData.monthlyListeners!.isNotEmpty) {
      return state.artistData.monthlyListeners!;
    }
    return '85.4M';
  }

  String _getFollowersFormatted(SearchArtistLoaded state) {
    if (_activePlatformFilter == 'youtube') {
      final subs = state.youtubeData?.totalSubscribers ?? 0;
      return subs > 0 ? Formatters.formatNumber(subs.toDouble()) : '48.2M';
    }
    final followers = state.artistData.totalFollowers;
    return followers > 0 ? Formatters.formatNumber(followers.toDouble()) : '94.6M';
  }

  List<TrackModel> _getFilteredTopTracks(SearchArtistLoaded state) {
    if (_activePlatformFilter == 'spotify') {
      return state.artistData.topTracks;
    }
    if (_activePlatformFilter == 'youtube') {
      return state.youtubeData?.videos ?? [];
    }
    if (_activePlatformFilter == 'apple') {
      return state.appleData?.topTracks ?? [];
    }

    // Combined: blend top tracks across platforms
    final list = <TrackModel>[];
    list.addAll(state.artistData.topTracks.take(5));
    if (state.youtubeData != null) {
      list.addAll(state.youtubeData!.videos.take(3));
    }
    if (state.appleData != null) {
      list.addAll(state.appleData!.topTracks.take(2));
    }
    if (list.isEmpty) {
      return state.artistData.topTracks;
    }
    return list;
  }

  String _calculateAverageCatalogAge(SearchArtistLoaded state) {
    if (_activePlatformFilter != 'combined') {
      final breakdown = state.valuationData.platformBreakdowns[_activePlatformFilter];
      if (breakdown != null && breakdown.averageDollarAge > 0) {
        return breakdown.averageDollarAge.toStringAsFixed(1);
      }
    }
    // Combined average
    final breakdowns = state.valuationData.platformBreakdowns.values.where((b) => b.averageDollarAge > 0);
    if (breakdowns.isNotEmpty) {
      final sum = breakdowns.fold(0.0, (acc, b) => acc + b.averageDollarAge);
      return (sum / breakdowns.length).toStringAsFixed(1);
    }
    return '4.2';
  }
}

// --- SliverPersistentHeader Delegate for Platform Filter ---
class _PlatformFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final bool hasSpotify;
  final bool hasYoutube;
  final bool hasApple;

  _PlatformFilterHeaderDelegate({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.hasSpotify,
    required this.hasYoutube,
    required this.hasApple,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip('combined', 'Combined (All Platforms)', const Color(0xFF00E5FF)),
            if (hasSpotify) ...[
              const SizedBox(width: 8),
              _buildFilterChip('spotify', 'Spotify', const Color(0xFF1DB954)),
            ],
            if (hasYoutube) ...[
              const SizedBox(width: 8),
              _buildFilterChip('youtube', 'YouTube', const Color(0xFFFF0000)),
            ],
            if (hasApple) ...[
              const SizedBox(width: 8),
              _buildFilterChip('apple', 'Apple Music', const Color(0xFFFA243C)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color accentColor) {
    final isSelected = activeFilter == key;
    return GestureDetector(
      onTap: () => onFilterChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PlatformFilterHeaderDelegate oldDelegate) {
    return oldDelegate.activeFilter != activeFilter ||
        oldDelegate.hasSpotify != hasSpotify ||
        oldDelegate.hasYoutube != hasYoutube ||
        oldDelegate.hasApple != hasApple;
  }
}
