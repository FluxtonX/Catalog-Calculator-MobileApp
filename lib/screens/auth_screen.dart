import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_cubit.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_state.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalog_calculator_flutter/core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;
  
  bool _isLoadingGoogle = false;
  bool _isLoadingEmail = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null && mounted) {
        final searchState = context.read<SearchArtistCubit>().state;
        if (searchState is SearchArtistLoaded) {
          // Scenario A: Artist already loaded before authentication
          if (mounted) context.go('/valuation');
        } else {
          final prefs = await SharedPreferences.getInstance();
          final lastQuery = prefs.getString('last_search_query') ?? '';
          if (lastQuery.isNotEmpty) {
            final encodedQuery = Uri.encodeComponent(lastQuery);
            if (mounted) context.go('/valuation?query=$encodedQuery');
          } else {
            // Scenario B: No active artist selected, navigate to search screen
            if (mounted) context.go('/search');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoadingGoogle = true;
      _errorMessage = null;
    });

    try {
      // 1. Initialize native Google Sign In
      // For iOS, we explicitly pass the iOS Client ID.
      // For Android, we only need the Web Client ID as serverClientId.
      const webClientId = '660487613110-68oirrtmp57ovl0gbikcmbdthdv2g5a3.apps.googleusercontent.com';
      const iosClientId = '660487613110-mf4qoet2e6ac1s7ov18m4h1e98n4bq4a.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? iosClientId : null,
        serverClientId: webClientId,
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled login
        return;
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      
      if (accessToken == null || idToken == null) {
        throw 'No Auth Token found.';
      }
      
      // 2. Sign in to Supabase using the native tokens
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGoogle = false;
        });
      }
    }
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }

    setState(() {
      _isLoadingEmail = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'catalogcalculator://login-callback/',
      );
      setState(() {
        _emailSent = true;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Logo & Title
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    border: Border.all(color: AppTheme.brandCyan.withValues(alpha: 0.35), width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandCyan.withValues(alpha: 0.15),
                        blurRadius: 28,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.calculate, size: 38, color: AppTheme.brandCyan);
                    },
                  ),
                ),
                
                const SizedBox(height: 28),
                
                Text(
                  'Welcome Back',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access catalog valuations',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                  ),
                ),
                
                const SizedBox(height: 36),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main Auth Box (Web Card: #0B101A with border #1A2333)
                Container(
                  padding: const EdgeInsets.all(24),
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
                    children: [
                      // Google Sign In
                      GestureDetector(
                        onTap: (_isLoadingGoogle || _isLoadingEmail) ? null : _handleGoogleSignIn,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoadingGoogle)
                                const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              else
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                                  height: 20,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, color: Colors.black87),
                                ),
                              const SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.inter(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        ],
                      ),
                      
                      const SizedBox(height: 22),

                      // Email Form
                      if (_emailSent)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Check your email!',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We sent a secure login link to ${_emailController.text}. Click the link to sign in.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _emailSent = false;
                                  _emailController.clear();
                                }),
                                child: Text(
                                  'Use a different email',
                                  style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.scaffoldBackground,
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextField(
                                controller: _emailController,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Enter your email address',
                                  hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.3)),
                                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withValues(alpha: 0.4)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            GestureDetector(
                              onTap: (_isLoadingGoogle || _isLoadingEmail) ? null : _handleEmailSignIn,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 17),
                                decoration: BoxDecoration(
                                  color: AppTheme.blueAccent,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.blueAccent.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isLoadingEmail)
                                      const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    else
                                      Text(
                                        'Continue with Email',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (!_isLoadingEmail) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                Text(
                  'By signing in, you agree to our Terms of Service\nand Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
