import 'package:supabase_flutter/supabase_flutter.dart';

class VoteRepository {
  final SupabaseClient _supabase;

  VoteRepository(this._supabase);

  Future<void> castVote({
    required String userId,
    required String contestId,
    required String googleMediaItemId,
    required Map<String, dynamic> metaData,
  }) async {
    // 1. Ensure photo exists in 'photos' table
    final photoResponse = await _supabase
        .from('photos')
        .select()
        .eq('contest_id', contestId)
        .eq('google_media_item_id', googleMediaItemId)
        .maybeSingle();

    String photoId;

    if (photoResponse == null) {
      // Insert new photo record
      final newPhoto = await _supabase
          .from('photos')
          .insert({
            'contest_id': contestId,
            'google_media_item_id': googleMediaItemId,
            'meta_data': metaData,
          })
          .select()
          .single();
      photoId = newPhoto['id'];
    } else {
      photoId = photoResponse['id'];
    }

    // 2. Insert vote
    await _supabase.from('votes').insert({
      'user_id': userId,
      'photo_id': photoId,
      'score': 1, // Default like
    });

    // 3. Increment vote count (optional, can be done via trigger or separate count query)
    // await _supabase.rpc('increment_vote_count', params: {'photo_id': photoId});
  }

  Future<int> getVoteCount(String photoId) async {
    final response = await _supabase
        .from('votes')
        .count(CountOption.exact)
        .eq('photo_id', photoId);
    return response;
  }

  Future<Set<String>> getMyVotes(String userId, String contestId) async {
    // We need to join votes with photos to filter by contestId
    // But Supabase simple query might be easier:
    // Select photo_id from votes where user_id = me
    // And then client side filter or just fetch all my votes for this contest's photos.

    // Better approach:
    // Fetch all photos for this contest first (we likely already have them or their IDs)
    // Then fetch votes where user_id = me AND photo_id IN (contest_photos)

    // Simplest for now: Fetch all votes by user, and we can filter.
    // Or, since we have google_media_item_id in photos, let's just fetch the photo_ids the user voted on.

    // However, the client knows google_media_item_id. The votes table has photo_id (UUID).
    // So we need to map back.

    final response = await _supabase
        .from('votes')
        .select('photo:photos(google_media_item_id)')
        .eq('user_id', userId);

    // Response structure: [{photo: {google_media_item_id: '...'}}, ...]
    final votedGoogleItemIds = <String>{};
    for (final record in response) {
      final photo = record['photo'] as Map<String, dynamic>?;
      if (photo != null) {
        votedGoogleItemIds.add(photo['google_media_item_id'] as String);
      }
    }
    return votedGoogleItemIds;
  }

  Future<Map<String, int>> getVoteCounts(String contestId) async {
    // Fetch all votes for photos in this contest
    // We join with photos table to filter by contest_id and get google_media_item_id
    final response = await _supabase
        .from('votes')
        .select('photo:photos!inner(contest_id, google_media_item_id)')
        .eq('photo.contest_id', contestId);

    final voteCounts = <String, int>{};

    for (final record in response) {
      final photo = record['photo'] as Map<String, dynamic>?;
      if (photo != null) {
        final googleMediaItemId = photo['google_media_item_id'] as String;
        voteCounts[googleMediaItemId] =
            (voteCounts[googleMediaItemId] ?? 0) + 1;
      }
    }
    return voteCounts;
  }
}
