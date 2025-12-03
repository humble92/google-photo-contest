import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humble_photo_contest/data/repositories/vote_repository.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';

final voteRepositoryProvider = Provider<VoteRepository>((ref) {
  return VoteRepository(ref.watch(supabaseClientProvider));
});
