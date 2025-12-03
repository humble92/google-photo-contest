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
        })
        .select()
        .single();

    return Contest.fromJson(response);
  }

  Future<List<Contest>> getMyContests(String userId) async {
    final response = await _supabase
        .from('contests')
        .select()
        .eq('host_user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Contest.fromJson(json)).toList();
  }
}
