import 'package:humble_photo_contest/data/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _supabase;

  UserRepository(this._supabase);

  /// Get current user's profile from public.users table
  Future<AppUser> getCurrentUser(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return AppUser.fromJson(response);
  }

  /// Get user's subscription tier
  Future<SubscriptionTier> getSubscriptionTier(String userId) async {
    final user = await getCurrentUser(userId);
    return user.subscriptionTier;
  }

  /// Check if user has premium subscription
  Future<bool> isPremiumUser(String userId) async {
    final tier = await getSubscriptionTier(userId);
    return tier == SubscriptionTier.premium;
  }
}
