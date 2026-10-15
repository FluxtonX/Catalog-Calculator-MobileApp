import 'package:catalog_calculator_flutter/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Color _bgColor = AppTheme.scaffoldBackground;
  final Color _brandGreen = AppTheme.primaryGreen;
  final Color _brandCyan = AppTheme.brandCyan;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.calculate_outlined,
      'badge1Icon': Icons.music_note,
      'badge1Text': '12.4M listeners',
      'badge2Icon': Icons.verified_user_outlined,
      'badge2Text': 'Data-backed',
      'stepBadge': 'WELCOME',
      'title1': 'Know What Your\n',
      'titleHighlight': 'Catalog',
      'title2': ' Is Really\nWorth',
      'subtitle': 'A quick, data-backed read on the value of your streaming catalog — built for artists, managers and labels.',
    },
    {
      'icon': Icons.search_rounded,
      'badge1Icon': Icons.circle,
      'badge1Text': 'Spotify',
      'badge1Color': AppTheme.spotifyGreen,
      'badge2Icon': Icons.play_circle_filled,
      'badge2Text': 'YouTube',
      'badge2Color': AppTheme.youtubeRed,
      'stepBadge': 'STEP 1',
      'title1': 'Search Any\n',
      'titleHighlight': 'Artist',
      'title2': ' In Seconds',
      'subtitle': 'Type a name and pick from live suggestions, then pull their top tracks from the platforms that matter to you.',
    },
    {
      'icon': Icons.insights_rounded,
      'badge1Icon': Icons.arrow_upward,
      'badge1Text': '+18% YoY',
      'badge2Icon': Icons.monetization_on,
      'badge2Text': r'$1.2M est.',
      'stepBadge': 'STEP 2',
      'title1': 'Get Instant\n',
      'titleHighlight': 'Valuations',
      'title2': ' With Full\nBreakdown',
      'subtitle': 'Toggle your data sources to see an indicative value with a clear per-platform breakdown, in seconds.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/search');
    }
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _brandCyan.withValues(alpha: 0.1),
                  border: Border.all(color: _brandCyan.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calculate, color: _brandCyan, size: 16),
              ),
              const SizedBox(width: 10),
              Text.rich(
                TextSpan(
                  text: 'Catalog ',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Calculator',
                      style: TextStyle(color: _brandCyan, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.go('/search'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'SKIP',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGraphic(Map<String, dynamic> pageData) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Main Box
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            border: Border.all(color: _brandCyan.withValues(alpha: 0.35), width: 1.5),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _brandCyan.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 8,
              )
            ],
          ),
          child: Icon(pageData['icon'] as IconData?, size: 72, color: _brandCyan),
        ),
        
        // Top Left Badge
        Positioned(
          top: -12,
          left: -40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Icon(
                  pageData['badge1Icon'] as IconData, 
                  size: 14, 
                  color: (pageData['badge1Color'] as Color?) ?? _brandGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  pageData['badge1Text'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom Right Badge
        Positioned(
          bottom: -12,
          right: -40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Icon(
                  pageData['badge2Icon'] as IconData, 
                  size: 14, 
                  color: (pageData['badge2Color'] as Color?) ?? const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
                Text(
                  pageData['badge2Text'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        
                        _buildGraphic(data),
                        
                        const Spacer(flex: 2),
                        
                        // Step Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _brandCyan.withValues(alpha: 0.1),
                            border: Border.all(color: _brandCyan.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: _brandCyan, size: 13),
                              const SizedBox(width: 6),
                              Text(
                                data['stepBadge'] as String,
                                style: GoogleFonts.inter(
                                  color: _brandCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Main Title
                        Text.rich(
                          TextSpan(
                            text: data['title1'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -1,
                            ),
                            children: [
                              TextSpan(
                                text: data['titleHighlight'] as String,
                                style: TextStyle(color: _brandCyan),
                              ),
                              TextSpan(
                                text: data['title2'] as String,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 14),
                        
                        // Subtitle
                        Text(
                          data['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        
                        const Spacer(flex: 3),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Area (Indicators and Next button)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 5,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? _brandCyan : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppTheme.blueAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.blueAccent.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentPage == 2) ...[
                            const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_currentPage < 2) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
