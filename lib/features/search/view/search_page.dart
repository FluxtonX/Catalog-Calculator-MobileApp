import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  
  final Map<String, bool> _platforms = {
    'spotify': true,
    'youtube': false,
    'apple': false,
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final selectedPlatform = _platforms.entries.firstWhere((e) => e.value, orElse: () => const MapEntry('spotify', true)).key;
    
    // Navigate directly to Valuation Page (Screen 3)
    final encodedQuery = Uri.encodeComponent(query);
    context.push('/valuation/$selectedPlatform/$encodedQuery');
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
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
                        color: AppTheme.brandGreen.withValues(alpha: 0.1),
                        border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(Icons.show_chart, color: AppTheme.brandGreen, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'FluxtonX',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),

                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandGreen.withValues(alpha: 0.05),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analyze Catalog',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter an artist or channel name to estimate their catalog value.',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Search Input
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldBackground,
                            border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'e.g. The Weeknd',
                              hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.2)),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.brandGreen),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text(
                          'SELECT PLATFORM',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildPlatformOption('spotify', 'Spotify', Icons.music_note, AppTheme.spotifyGreen),
                        _buildPlatformOption('youtube', 'YouTube', Icons.play_circle_filled, AppTheme.youtubeRed),
                        _buildPlatformOption('apple', 'Apple Music', Icons.apple, AppTheme.appleSilver),

                        const SizedBox(height: 32),
                        
                        // Search Button
                        GestureDetector(
                          onTap: hasInput ? _handleSearch : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: hasInput ? AppTheme.brandGreen.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calculate, 
                                  color: hasInput ? AppTheme.brandGreen : Colors.white24, 
                                  size: 20
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Calculate Valuation',
                                  style: GoogleFonts.inter(
                                    color: hasInput ? AppTheme.brandGreen : Colors.white24,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformOption(String key, String title, IconData icon, Color color) {
    final isSelected = _platforms[key] ?? false;
    return GestureDetector(
      onTap: () {
        setState(() {
          _platforms.updateAll((k, v) => false); // Single select for now
          _platforms[key] = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.scaffoldBackground,
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white38),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
