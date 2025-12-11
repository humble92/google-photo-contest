import 'package:flutter_test/flutter_test.dart';
import 'package:humble_photo_contest/data/models/user.dart';

void main() {
  group('AppUser Model Tests', () {
    test('fromJson creates AppUser with all fields', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'avatar_url': 'https://example.com/avatar.jpg',
        'provider_id': 'google.com',
        'subscription_tier': 'premium',
        'created_at': '2024-01-01T10:00:00Z',
        'updated_at': '2024-06-15T12:30:00Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.providerId, 'google.com');
      expect(user.subscriptionTier, SubscriptionTier.premium);
      expect(user.createdAt, DateTime.parse('2024-01-01T10:00:00Z'));
      expect(user.updatedAt, DateTime.parse('2024-06-15T12:30:00Z'));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'user-456',
        'email': 'minimal@example.com',
        'display_name': null,
        'avatar_url': null,
        'provider_id': null,
        'subscription_tier': 'free',
        'created_at': '2024-02-01T08:00:00Z',
        'updated_at': '2024-02-01T08:00:00Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.displayName, null);
      expect(user.avatarUrl, null);
      expect(user.providerId, null);
    });

    test('fromJson parses free subscription tier', () {
      final json = {
        'id': 'user-free',
        'email': 'free@example.com',
        'subscription_tier': 'free',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.subscriptionTier, SubscriptionTier.free);
      expect(user.isPremium, false);
    });

    test('fromJson parses premium subscription tier', () {
      final json = {
        'id': 'user-premium',
        'email': 'premium@example.com',
        'subscription_tier': 'premium',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.subscriptionTier, SubscriptionTier.premium);
      expect(user.isPremium, true);
    });

    test('fromJson defaults to free tier when subscription_tier is null', () {
      final json = {
        'id': 'user-null-tier',
        'email': 'null@example.com',
        'subscription_tier': null,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.subscriptionTier, SubscriptionTier.free);
      expect(user.isPremium, false);
    });

    test('fromJson defaults to free tier on invalid subscription_tier', () {
      final json = {
        'id': 'user-invalid-tier',
        'email': 'invalid@example.com',
        'subscription_tier': 'invalid_tier',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.subscriptionTier, SubscriptionTier.free);
    });

    test('isPremium getter returns correct value for free tier', () {
      final user = AppUser(
        id: 'user-test-free',
        email: 'test@free.com',
        subscriptionTier: SubscriptionTier.free,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.isPremium, false);
    });

    test('isPremium getter returns correct value for premium tier', () {
      final user = AppUser(
        id: 'user-test-premium',
        email: 'test@premium.com',
        subscriptionTier: SubscriptionTier.premium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.isPremium, true);
    });

    test('fromJson handles Google provider', () {
      final json = {
        'id': 'user-google',
        'email': 'google@example.com',
        'provider_id': 'google.com',
        'subscription_tier': 'free',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.providerId, 'google.com');
    });
  });
}
