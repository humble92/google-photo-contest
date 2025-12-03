import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humble_photo_contest/data/repositories/contest_repository.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';

final contestRepositoryProvider = Provider<ContestRepository>((ref) {
  return ContestRepository(ref.watch(supabaseClientProvider));
});
