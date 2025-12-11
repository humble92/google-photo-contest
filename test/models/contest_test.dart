import 'package:flutter_test/flutter_test.dart';
import 'package:humble_photo_contest/data/models/contest.dart';

void main() {
  group('Contest Model Tests', () {
    test('fromJson creates Contest with all fields', () {
      final json = {
        'id': 'contest-123',
        'host_user_id': 'user-456',
        'title': 'Summer Photo Contest',
        'description': 'Best summer photos',
        'status': 'active',
        'start_at': '2024-06-01T00:00:00Z',
        'end_at': '2024-06-30T23:59:59Z',
        'voting_type': 'like',
        'show_vote_counts': true,
        'is_private': false,
        'pass_key': null,
        'created_at': '2024-05-01T12:00:00Z',
      };

      final contest = Contest.fromJson(json);

      expect(contest.id, 'contest-123');
      expect(contest.hostUserId, 'user-456');
      expect(contest.title, 'Summer Photo Contest');
      expect(contest.description, 'Best summer photos');
      expect(contest.status, ContestStatus.active);
      expect(contest.startAt, DateTime.parse('2024-06-01T00:00:00Z'));
      expect(contest.endAt, DateTime.parse('2024-06-30T23:59:59Z'));
      expect(contest.votingType, VotingType.like);
      expect(contest.showVoteCounts, true);
      expect(contest.isPrivate, false);
      expect(contest.passKey, null);
      expect(contest.createdAt, DateTime.parse('2024-05-01T12:00:00Z'));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'contest-789',
        'host_user_id': 'user-101',
        'title': 'Minimal Contest',
        'description': null,
        'status': 'draft',
        'start_at': null,
        'end_at': null,
        'voting_type': 'stars',
        'show_vote_counts': false,
        'is_private': null,
        'pass_key': null,
        'created_at': '2024-05-15T10:00:00Z',
      };

      final contest = Contest.fromJson(json);

      expect(contest.description, null);
      expect(contest.startAt, null);
      expect(contest.endAt, null);
      expect(contest.isPrivate, false); // defaults to false
      expect(contest.passKey, null);
    });

    test('fromJson parses ContestStatus enum correctly', () {
      final draftJson = {
        'status': 'draft',
        'id': '1',
        'host_user_id': '1',
        'title': 'Test',
        'voting_type': 'like',
        'show_vote_counts': false,
        'created_at': '2024-01-01T00:00:00Z',
      };
      final activeJson = {
        'status': 'active',
        'id': '2',
        'host_user_id': '2',
        'title': 'Test',
        'voting_type': 'like',
        'show_vote_counts': false,
        'created_at': '2024-01-01T00:00:00Z',
      };
      final endedJson = {
        'status': 'ended',
        'id': '3',
        'host_user_id': '3',
        'title': 'Test',
        'voting_type': 'like',
        'show_vote_counts': false,
        'created_at': '2024-01-01T00:00:00Z',
      };

      expect(Contest.fromJson(draftJson).status, ContestStatus.draft);
      expect(Contest.fromJson(activeJson).status, ContestStatus.active);
      expect(Contest.fromJson(endedJson).status, ContestStatus.ended);
    });

    test('fromJson handles invalid status with default', () {
      final json = {
        'id': 'contest-999',
        'host_user_id': 'user-999',
        'title': 'Invalid Status Contest',
        'status': 'invalid_status',
        'voting_type': 'like',
        'show_vote_counts': false,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final contest = Contest.fromJson(json);
      expect(contest.status, ContestStatus.draft); // defaults to draft
    });

    test('fromJson parses VotingType enum correctly', () {
      final likeJson = {
        'voting_type': 'like',
        'id': '1',
        'host_user_id': '1',
        'title': 'Test',
        'status': 'draft',
        'show_vote_counts': false,
        'created_at': '2024-01-01T00:00:00Z',
      };
      final starsJson = {
        'voting_type': 'stars',
        'id': '2',
        'host_user_id': '2',
        'title': 'Test',
        'status': 'draft',
        'show_vote_counts': false,
        'created_at': '2024-01-01T00:00:00Z',
      };
      final categoriesJson = {
        'voting_type': 'categories',
        'id': '3',
        'host_user_id': '3',
        'title': 'Test',
        'status': 'draft',
        'show_vote_counts': false,
        'created_at': '2024-01-01T00:00:00Z',
      };

      expect(Contest.fromJson(likeJson).votingType, VotingType.like);
      expect(Contest.fromJson(starsJson).votingType, VotingType.stars);
      expect(
        Contest.fromJson(categoriesJson).votingType,
        VotingType.categories,
      );
    });

    test('fromJson handles invalid voting type with default', () {
      final json = {
        'id': 'contest-888',
        'host_user_id': 'user-888',
        'title': 'Invalid Voting Type',
        'status': 'draft',
        'voting_type': 'invalid_type',
        'show_vote_counts': false,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final contest = Contest.fromJson(json);
      expect(contest.votingType, VotingType.like); // defaults to like
    });

    test('fromJson handles private contest with passkey', () {
      final json = {
        'id': 'contest-private',
        'host_user_id': 'user-private',
        'title': 'Private Contest',
        'status': 'active',
        'voting_type': 'like',
        'show_vote_counts': true,
        'is_private': true,
        'pass_key': 'secret123',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final contest = Contest.fromJson(json);
      expect(contest.isPrivate, true);
      expect(contest.passKey, 'secret123');
    });
  });
}
