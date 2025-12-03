import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humble_photo_contest/data/repositories/photo_repository.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(ref.watch(supabaseClientProvider));
});
