import 'package:flutter/foundation.dart';
import 'package:humble_photo_contest/data/models/contest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContestRepository {
  final SupabaseClient _supabase;

  ContestRepository(this._supabase);

  Future<Contest> createContest({
    required String hostUserId,
    required String title,
    String? description,
    required bool showVoteCounts,
    bool isPrivate = false,
    String? passKey,
  }) async {
    final response = await _supabase
        .from('contests')
        .insert({
          'host_user_id': hostUserId,
          'title': title,
          'description': description,
          'status': 'draft', // Default to draft
          'voting_type': 'like', // Default to like
          'show_vote_counts': showVoteCounts,
          'is_private': isPrivate,
          'pass_key': passKey,
        })
        .select()
        .single();

    return Contest.fromJson(response);
  }

  Future<Contest> updateContest({
    required String contestId,
    String? title,
    String? description,
    String? status,
    bool? showVoteCounts,
    bool? isPrivate,
    String? passKey,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (status != null) updates['status'] = status;
    if (showVoteCounts != null) updates['show_vote_counts'] = showVoteCounts;
    if (isPrivate != null) updates['is_private'] = isPrivate;
    if (passKey != null) updates['pass_key'] = passKey;

    final response = await _supabase
        .from('contests')
        .update(updates)
        .eq('id', contestId)
        .select()
        .single();

    return Contest.fromJson(response);
  }

  Future<void> deleteContest(String contestId) async {
    // 1. Get all photos for this contest to delete their storage files
    final photos = await _supabase
        .from('photos')
        .select('storage_path')
        .eq('contest_id', contestId);

    // 2. Delete storage files
    for (final photo in photos as List) {
      try {
        final storagePath = photo['storage_path'] as String;
        await _supabase.storage.from('contest_photos').remove([storagePath]);
      } catch (e) {
        // Continue even if some files fail to delete
        debugPrint('Failed to delete storage file: $e');
      }
    }

    // 3. Delete contest (photos and votes will CASCADE delete automatically)
    await _supabase.from('contests').delete().eq('id', contestId);
  }

  Future<List<Contest>> getMyContests(String userId) async {
    final response = await _supabase
        .from('contests')
        .select()
        .eq('host_user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Contest.fromJson(json)).toList();
  }

  /// Get all contests NOT hosted by the current user
  /// This includes both public and private contests (private ones require pass key)
  Future<List<Contest>> getAllOtherContests(String currentUserId) async {
    final response = await _supabase
        .from('contests')
        .select()
        .neq('host_user_id', currentUserId) // NOT equal to current user
        .or('status.eq.active,status.eq.ended') // Only active or ended
        .order('created_at', ascending: false);

    return (response as List).map((json) => Contest.fromJson(json)).toList();
  }

  Future<Contest> getContestById(String contestId) async {
    final response = await _supabase
        .from('contests')
        .select()
        .eq('id', contestId)
        .single();

    return Contest.fromJson(response);
  }

  /// Verify if the provided pass key matches the contest's pass key
  Future<bool> verifyPassKey(String contestId, String passKey) async {
    final contest = await getContestById(contestId);
    return contest.passKey == passKey;
  }

  /// Check if user can access a private contest
  /// Returns true if contest is public, user is host, or valid pass key provided
  Future<bool> canAccessContest({
    required Contest contest,
    required String userId,
    String? passKey,
  }) async {
    // Public contests are accessible to everyone
    if (!contest.isPrivate) return true;

    // Host can always access their own contests
    if (contest.hostUserId == userId) return true;

    // Verify pass key for private contests
    if (passKey != null && passKey == contest.passKey) return true;

    return false;
  }
}
