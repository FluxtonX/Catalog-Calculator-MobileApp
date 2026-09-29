import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _driftController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoRotate;
  
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _glowPulse;
  
  late Animation<double> _driftX1;
  late Animation<double> _driftY1;
  late Animation<double> _driftX2;
  late Animation<double> _driftY2;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // --- Entry Animations ---
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    
    _logoRotate = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // --- Continuous Animations ---
    _glowPulse = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Background Blobs Drifting
    _driftX1 = Tween<double>(begin: -150, end: -50).animate(
      CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine)
    );
    _driftY1 = Tween<double>(begin: -150, end: -100).animate(
      CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine)
    );
    
    _driftX2 = Tween<double>(begin: -150, end: -250).animate(
      CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine)
    );
    _driftY2 = Tween<double>(begin: -150, end: -50).animate(
      CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine)
    );

    // Start animations
    _mainController.forward().then((_) {
      _pulseController.repeat(reverse: true);
    });
    
    _driftController.repeat(reverse: true);

    Timer(const Duration(milliseconds: 4000), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _driftController.dispose();
    super.dispose();
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
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10b981).withOpacity(0.06), // Emerald
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF10b981).withOpacity(0.12),
                              blurRadius: 120),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: _driftY2.value,
                    left: _driftX2.value,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3b82f6).withOpacity(0.05), // Blue
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF3b82f6).withOpacity(0.1),
                              blurRadius: 150),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Rotating Entry and Pulsing Glow
                AnimatedBuilder(
                  animation: Listenable.merge([_mainController, _pulseController]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: RotationTransition(
                        turns: _logoRotate,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.02),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10b981)
                                      .withOpacity(0.2 * _glowPulse.value),
                                  blurRadius: 70 * _glowPulse.value,
                                  spreadRadius: 15 * _glowPulse.value,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF3b82f6)
                                      .withOpacity(0.1 * _glowPulse.value),
                                  blurRadius: 40 * _glowPulse.value,
                                  spreadRadius: 5 * _glowPulse.value,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Sliding & Fading Text Content
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFcbd5e1)], // White to Slate 300
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'Catalog Calculator',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Professional sub-pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: const Color(0xFF10b981).withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10b981).withOpacity(0.1),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Text(
                          'PROFESSIONAL VALUATIONS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                            color: const Color(0xFF6ee7b7), // Emerald 300
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
