import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humble_photo_contest/data/services/google_photos_service.dart';

final googlePhotosServiceProvider = Provider<GooglePhotosService>((ref) {
  return GooglePhotosService();
});
