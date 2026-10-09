import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

GoogleSignIn _createGoogleSignIn() {
  const webClientId =
      '660487613110-68oirrtmp57ovl0gbikcmbdthdv2g5a3.apps.googleusercontent.com';
  const iosClientId =
      '660487613110-mf4qoet2e6ac1s7ov18m4h1e98n4bq4a.apps.googleusercontent.com';

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );
  }

  return GoogleSignIn(
    serverClientId: webClientId,
  );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = _createGoogleSignIn();

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  /// Native Google Sign In for Android and iOS
  Future<User?> signInWithGoogle() async {
    try {
      // Disconnect/sign out any previous session to allow picking account
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled account selection popup
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
          'Google did not return an ID token. Make sure the Web Client ID is configured correctly.',
        );
      }

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response.user;
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException: ${e.message}');
      throw Exception(e.message);
    } on PlatformException catch (e, stackTrace) {
      debugPrint(
        'Google Sign-In PlatformException: ${e.code} - ${e.message} - ${e.details}',
      );
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(_googleSignInErrorMessage(e));
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle general error: $e');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _supabase.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  String _googleSignInErrorMessage(PlatformException e) {
    if (e.code == 'sign_in_failed') {
      return 'Google Sign-In is not configured correctly. Please check Android SHA-1 fingerprint and OAuth client IDs.';
    }
    if (e.code == 'network_error') {
      return 'Network error. Please check your internet connection.';
    }
    return e.message ?? 'Google Sign-In failed. Please try again.';
  }
}
