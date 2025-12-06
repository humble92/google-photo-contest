import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humble_photo_contest/data/models/user.dart';
import 'package:humble_photo_contest/data/repositories/contest_repository.dart';
import 'package:humble_photo_contest/data/repositories/user_repository.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';

final contestRepositoryProvider = Provider<ContestRepository>((ref) {
  return ContestRepository(ref.watch(supabaseClientProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(supabaseClientProvider));
});

/// Get current app user from public.users table
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) return null;

  try {
    return await ref.read(userRepositoryProvider).getCurrentUser(authUser.id);
  } catch (e) {
    // User might not exist in public.users yet (new user)
    return null;
  }
});

/// Get current user's subscription tier
final subscriptionTierProvider = FutureProvider<SubscriptionTier>((ref) async {
  final appUser = await ref.watch(currentAppUserProvider.future);
  return appUser?.subscriptionTier ?? SubscriptionTier.free;
});

/// Check if current user is premium
final isPremiumUserProvider = FutureProvider<bool>((ref) async {
  final tier = await ref.watch(subscriptionTierProvider.future);
  return tier == SubscriptionTier.premium;
});
