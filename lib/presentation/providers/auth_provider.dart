// ignore: avoid_web_libraries_in_flutter
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:humble_photo_contest/core/constants/env_constants.dart';
import 'package:humble_photo_contest/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  // Platform‑specific client IDs
  String? clientId;
  String? serverClientId;

  if (kIsWeb) {
    // Web uses the Web client ID as the clientId
    clientId = EnvConstants.googleWebClientId;
  } else if (Platform.isAndroid) {
    // For Android: Use Web Client ID to get access tokens that work with Google APIs
    // The Android Client ID is only for Play Services authentication
    clientId = EnvConstants.googleWebClientId;
    serverClientId = EnvConstants.googleWebClientId;
  } else if (Platform.isIOS) {
    clientId = EnvConstants.googleIosClientId;
  }

  // IMPORTANT: On Web, including photo scopes prevents ID token from being returned
  // by Google Identity Services (GIS). So we only include basic scopes for Web.
  // On Android/iOS, we can include all scopes upfront.
  final List<String> baseScopes = ['email', 'openid'];
  final List<String> photoScopes = [
    'https://www.googleapis.com/auth/photoslibrary.readonly',
    'https://www.googleapis.com/auth/photoslibrary',
  ];

  // For Web: only basic scopes to ensure ID token is returned
  // For mobile: include photo scopes upfront
  final List<String> scopes = kIsWeb ? baseScopes : [...baseScopes, ...photoScopes];

  return GoogleSignIn(
    clientId: clientId,
    serverClientId: serverClientId,
    scopes: scopes,
    // forceCodeForRefreshToken should be false for Web to use the implicit flow correctly
    // forceCodeForRefreshToken: !kIsWeb,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(googleSignInProvider),
  );
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user;
});
