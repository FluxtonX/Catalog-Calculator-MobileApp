import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/search');
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
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'catalogcalculator://login-callback/',
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
      backgroundColor: const Color(0xFF041510), // Deep emerald to match app theme
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Logo & Title
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF041510),
                    border: Border.all(color: const Color(0xFF34d399).withOpacity(0.3), width: 2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34d399).withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ]
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.bar_chart_rounded, size: 40, color: Color(0xFF34d399));
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Welcome Back',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access catalog valuations',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 48),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
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

                // Main Auth Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081F17),
                    border: Border.all(color: const Color(0xFF34d399).withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(24),
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
                            borderRadius: BorderRadius.circular(16),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // Email Form
                      if (_emailSent)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34d399).withOpacity(0.1),
                            border: Border.all(color: const Color(0xFF34d399).withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Color(0xFF34d399), size: 48),
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
                                  style: GoogleFonts.inter(color: const Color(0xFF34d399), fontWeight: FontWeight.bold),
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
                                color: const Color(0xFF041510),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _emailController,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Enter your email address',
                                  hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.3)),
                                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.4)),
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
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34d399),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF34d399).withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isLoadingEmail)
                                      const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF041510)),
                                      )
                                    else
                                      Text(
                                        'Continue with Email',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF041510),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (!_isLoadingEmail) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, color: Color(0xFF041510), size: 18),
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
                    color: Colors.white.withOpacity(0.4),
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
