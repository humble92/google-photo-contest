enum SubscriptionTier { free, premium }

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? providerId;
  final SubscriptionTier subscriptionTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.providerId,
    required this.subscriptionTier,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      providerId: json['provider_id'],
      subscriptionTier: _parseSubscriptionTier(json['subscription_tier']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  static SubscriptionTier _parseSubscriptionTier(String? tier) {
    if (tier == null) return SubscriptionTier.free;
    return SubscriptionTier.values.firstWhere(
      (e) => e.toString().split('.').last == tier,
      orElse: () => SubscriptionTier.free,
    );
  }

  bool get isPremium => subscriptionTier == SubscriptionTier.premium;
}
