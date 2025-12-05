import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:humble_photo_contest/data/models/photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class PhotoRepository {
  final SupabaseClient _supabase;

  PhotoRepository(this._supabase);

  Future<List<Photo>> getPhotos(String contestId) async {
    final response = await _supabase
        .from('photos')
        .select()
        .eq('contest_id', contestId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Photo.fromJson(json)).toList();
  }

  Future<Photo> uploadPhoto({
    required String contestId,
    required String userId,
    required File file,
  }) async {
    final fileExt = path.extension(file.path);
    final fileName = '${DateTime.now().toIso8601String()}_$userId$fileExt';
    final storagePath = '$contestId/$fileName';

    // 1. Upload to Storage
    await _supabase.storage
        .from('contest_photos')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // 2. Create DB Record
    return _createPhotoRecord(contestId, userId, storagePath);
  }

  Future<Photo> uploadPhotoFromBytes({
    required String contestId,
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final storagePath = '$contestId/$fileName';

    // 1. Upload to Storage (using uploadBinary for web compatibility)
    await _supabase.storage
        .from('contest_photos')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // 2. Create DB Record
    return _createPhotoRecord(contestId, userId, storagePath);
  }

  Future<Photo> uploadPhotoFromUrl({
    required String contestId,
    required String userId,
    required String imageUrl,
  }) async {
    // 1. Download Image
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image: ${response.statusCode}');
    }

    Uint8List imageBytes = response.bodyBytes;

    // 2. Compress Image
    // We try to compress to jpeg with 80% quality
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 1920,
        minWidth: 1920,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      imageBytes = compressedBytes;
    } catch (e) {
      // Fallback to original bytes if compression fails (e.g. on unsupported platforms or formats)
      debugPrint('Compression failed: $e');
    }

    final fileName = '${DateTime.now().toIso8601String()}_$userId.jpg';
    final storagePath = '$contestId/$fileName';

    // 3. Upload to Storage
    await _supabase.storage
        .from('contest_photos')
        .uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: 'image/jpeg',
          ),
        );

    // 4. Create DB Record
    return _createPhotoRecord(contestId, userId, storagePath);
  }

  Future<Photo> _createPhotoRecord(
    String contestId,
    String userId,
    String storagePath,
  ) async {
    final response = await _supabase
        .from('photos')
        .insert({
          'contest_id': contestId,
          'user_id': userId,
          'storage_path': storagePath,
          'meta_data': {},
        })
        .select()
        .single();

    return Photo.fromJson(response);
  }

  String getPhotoUrl(String storagePath) {
    return _supabase.storage.from('contest_photos').getPublicUrl(storagePath);
  }
}
