import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late AnimationController _driftController;
  late Animation<double> _driftX1;
  late Animation<double> _driftY1;
  late Animation<double> _driftX2;
  late Animation<double> _driftY2;

  final List<Map<String, String>> slides = [
    {
      'title': 'Professional Catalog Valuation',
      'description':
          'Instantly analyze and value music artist catalogs using real-time streaming data.',
      'icon': 'assets/images/logo.png',
    },
    {
      'title': 'Comprehensive Metrics',
      'description':
          'Get deep insights across Spotify, YouTube, and iTunes to determine true market value.',
      'icon': 'assets/images/logo.png',
    },
    {
      'title': 'Track Your Portfolio',
      'description':
          'Save valuations, monitor changes, and get real-time alerts for your followed artists.',
      'icon': 'assets/images/logo.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Ambient Background Drift Animation
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _driftX1 = Tween<double>(begin: -100, end: 50).animate(
        CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine));
    _driftY1 = Tween<double>(begin: -100, end: 20).animate(
        CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine));
    _driftX2 = Tween<double>(begin: -200, end: -50).animate(
        CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine));
    _driftY2 = Tween<double>(begin: 100, end: 250).animate(
        CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine));

    _driftController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      context.go('/login');
    }
  }

  void _skip() {
    context.go('/login');
  }

  void _back() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep Slate 950
      body: Stack(
        children: [
          // Ambient Animated Drifting Blobs
          AnimatedBuilder(
            animation: _driftController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: _driftY1.value,
                    right: _driftX1.value,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10b981).withOpacity(0.05), // Emerald
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10b981).withOpacity(0.15),
                            blurRadius: 150,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: _driftY2.value,
                    left: _driftX2.value,
                    child: Container(
                      width: 600,
                      height: 600,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3b82f6).withOpacity(0.04), // Blue
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3b82f6).withOpacity(0.12),
                            blurRadius: 180,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Navigation (Back / Skip)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentIndex > 0 ? 1.0 : 0.0,
                        child: GestureDetector(
                          onTap: _back,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                          ),
                        ),
                      ),
                      
                      // Skip Button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentIndex < slides.length - 1 ? 1.0 : 0.0,
                        child: GestureDetector(
                          onTap: _skip,
                          child: Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF34d399), // Emerald 400
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // PageView Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      // Scale and Opacity effect for the active page
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                          }
                          return Transform.scale(
                            scale: Curves.easeOut.transform(value),
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Glassmorphism Floating Card
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                  child: Container(
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 30,
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Floating Icon
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF10b981).withOpacity(0.1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF10b981).withOpacity(0.2),
                                                blurRadius: 40,
                                                spreadRadius: 5,
                                              )
                                            ],
                                          ),
                                          child: Image.asset(
                                            slide['icon']!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 48),
                                        Text(
                                          slide['title']!,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          slide['description']!,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF94a3b8), // Slate 400
                                            fontSize: 16,
                                            height: 1.6,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32, bottom: 48, top: 20),
                  child: Column(
                    children: [
                      // Animated Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCirc,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            height: 6,
                            width: _currentIndex == index ? 32 : 12,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? const Color(0xFF10b981) // Emerald 500
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: _currentIndex == index
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10b981).withOpacity(0.5),
                                        blurRadius: 10,
                                      )
                                    ]
                                  : [],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Primary CTA Button
                      GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10b981), Color(0xFF059669)], // Emerald 500 to 600
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10b981).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            _currentIndex == slides.length - 1
                                ? 'Get Started'
                                : 'Continue',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
