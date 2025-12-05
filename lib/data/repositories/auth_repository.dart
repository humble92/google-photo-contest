import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._supabase, this._googleSignIn);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  /// Sign in with Google
  /// - Web: Uses Supabase's native OAuth (redirect-based)
  /// - Mobile: Uses google_sign_in package with ID token
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _signInWithGoogleWeb();
    } else {
      await _signInWithGoogleMobile();
    }
  }

  /// Web: Use Supabase's native OAuth flow
  Future<void> _signInWithGoogleWeb() async {
    debugPrint('AuthRepository: Starting Supabase OAuth for Web...');

    // Get the current URL for redirect (without hash/query params)
    final currentUrl = Uri.base.origin;
    debugPrint('AuthRepository: Redirect URL: $currentUrl');

    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: currentUrl,
      scopes: 'email openid profile',
      queryParams: {'access_type': 'offline', 'prompt': 'consent'},
    );

    // Note: This is a redirect-based flow on web.
    // The page will redirect to Google and back to the app.
    // The auth state will be updated via authStateChanges stream.
  }

  /// Mobile: Use google_sign_in package
  Future<AuthResponse> _signInWithGoogleMobile() async {
    try {
      debugPrint('AuthRepository: Starting Google Sign-In for Mobile...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign-In aborted.';
      }
      debugPrint('AuthRepository: Google user signed in: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      debugPrint('AuthRepository: accessToken present: ${accessToken != null}');
      debugPrint('AuthRepository: idToken present: ${idToken != null}');

      if (accessToken == null) {
        throw 'No Access Token found.';
      }

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      debugPrint('AuthRepository: Signing in to Supabase with ID token...');
      final authResponse = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      debugPrint('AuthRepository: Supabase sign-in successful');

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _supabase.auth.signOut();
  }
}
