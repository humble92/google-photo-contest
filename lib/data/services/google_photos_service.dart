import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:humble_photo_contest/core/constants/env_constants.dart';
import 'package:humble_photo_contest/data/models/google_album.dart';
import 'package:humble_photo_contest/data/models/google_media_item.dart';

class GooglePhotosService {
  // Dedicated GoogleSignIn instance for Photos API with required scopes
  static GoogleSignIn? _photosGoogleSignIn;
  
  static GoogleSignIn get _photos {
    _photosGoogleSignIn ??= GoogleSignIn(
      clientId: kIsWeb ? EnvConstants.googleWebClientId : null,
      scopes: [
        'https://www.googleapis.com/auth/photoslibrary.readonly',
        'https://www.googleapis.com/auth/photoslibrary',
      ],
    );
    return _photosGoogleSignIn!;
  }

  GooglePhotosService();

  Future<Map<String, String>> _getAuthHeaders() async {
    if (kIsWeb) {
      // Web: Photos API access is not yet supported due to OAuth limitations
      // TODO: Implement backend-based solution for web
      throw Exception(
        'Photos API access is not yet supported on Web. '
        'Please use the mobile app to access Google Photos.',
      );
    }

    // Mobile: Use dedicated GoogleSignIn for Photos API
    // We need to disconnect first to ensure we get a fresh token with photo scopes
    // (signInSilently would reuse the main app's session without photo scopes)
    GoogleSignInAccount? photosUser = _photos.currentUser;
    
    if (photosUser == null) {
      debugPrint('GooglePhotosService: No Photos user, disconnecting and signing in fresh...');
      await _photos.disconnect();
      photosUser = await _photos.signIn();
    }
    
    if (photosUser == null) {
      throw Exception('Photos authorization required. Please grant access to Google Photos.');
    }

    final auth = await photosUser.authentication;
    final accessToken = auth.accessToken;

    if (accessToken == null) {
      throw Exception('No access token available for Photos API');
    }

    debugPrint('GooglePhotosService: Got Photos access token: ${accessToken.substring(0, 20)}...');

    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  Future<List<GoogleAlbum>> getAlbums({String? pageToken}) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse(
      'https://photoslibrary.googleapis.com/v1/albums?pageSize=50',
    );

    debugPrint('GooglePhotosService: Calling Albums API...');
    debugPrint('GooglePhotosService: Headers: ${headers.keys.toList()}');
    
    final response = await http.get(uri, headers: headers);
    
    debugPrint('GooglePhotosService: Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> albumsJson = data['albums'] ?? [];
      debugPrint('GooglePhotosService: Found ${albumsJson.length} albums');
      return albumsJson.map((json) => GoogleAlbum.fromJson(json)).toList();
    } else {
      debugPrint('GooglePhotosService: Error response: ${response.body}');
      throw Exception('Failed to load albums: ${response.body}');
    }
  }

  Future<List<GoogleMediaItem>> getMediaItems(String albumId) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse(
      'https://photoslibrary.googleapis.com/v1/mediaItems:search',
    );

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'albumId': albumId, 'pageSize': 100}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> itemsJson = data['mediaItems'] ?? [];
      return itemsJson.map((json) => GoogleMediaItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load media items: ${response.body}');
    }
  }
}
