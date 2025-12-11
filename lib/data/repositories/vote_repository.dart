import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoteRepository {
  final SupabaseClient _supabase;

  VoteRepository(this._supabase);

  Future<void> castVote({
    required String userId,
    required String contestId,
    required String photoId,
  }) async {
    // Insert vote
    await _supabase.from('votes').insert({
      'user_id': userId,
      'photo_id': photoId,
      'score': 1, // Default like
    });
  }

  /// Remove a vote (unvote)
  /// This deletes the vote record and triggers the decrement_photo_vote_count function
  Future<void> removeVote({
    required String userId,
    required String photoId,
  }) async {
    await _supabase
        .from('votes')
        .delete()
        .eq('user_id', userId)
        .eq('photo_id', photoId);
  }

  Future<int> getVoteCount(String photoId) async {
    final response = await _supabase
        .from('votes')
        .count(CountOption.exact)
        .eq('photo_id', photoId);
    return response;
  }

  Future<Set<String>> getMyVotes(String userId, String contestId) async {
    debugPrint('🔍 Fetching votes for user: $userId, contest: $contestId');

    // Fetch all votes by user for photos in this contest
    final response = await _supabase
        .from('votes')
        .select('photo_id, photo:photos!inner(contest_id)')
        .eq('user_id', userId)
        .eq('photo.contest_id', contestId);

    debugPrint('🔍 getMyVotes response: $response');
    debugPrint('🔍 Response type: ${response.runtimeType}');
    debugPrint('🔍 Response length: ${(response as List).length}');

    final votedPhotoIds = <String>{};
    for (final record in response) {
      debugPrint('🔍 Processing record: $record');
      final photoId = record['photo_id'] as String;
      debugPrint('🔍 Adding photo_id: $photoId');
      votedPhotoIds.add(photoId);
    }

    debugPrint('✅ Final votedPhotoIds: $votedPhotoIds');
    return votedPhotoIds;
  }

  Future<Map<String, int>> getVoteCounts(String contestId) async {
    // Fetch all votes for photos in this contest
    final response = await _supabase
        .from('votes')
        .select('photo_id, photo:photos!inner(contest_id)')
        .eq('photo.contest_id', contestId);

    final voteCounts = <String, int>{};

    for (final record in response) {
      final photoId = record['photo_id'] as String;
      voteCounts[photoId] = (voteCounts[photoId] ?? 0) + 1;
    }
    return voteCounts;
  }
}
