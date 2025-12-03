import 'dart:io';
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
    final response = await _supabase
        .from('photos')
        .insert({
          'contest_id': contestId,
          'user_id': userId,
          'storage_path': storagePath,
          'metadata': {}, // Can add width/height here if needed
        })
        .select()
        .single();

    return Photo.fromJson(response);
  }

  String getPhotoUrl(String storagePath) {
    return _supabase.storage.from('contest_photos').getPublicUrl(storagePath);
  }
}
