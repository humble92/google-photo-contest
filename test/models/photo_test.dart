import 'package:flutter_test/flutter_test.dart';
import 'package:humble_photo_contest/data/models/photo.dart';

void main() {
  group('Photo Model Tests', () {
    test('fromJson creates Photo with all fields', () {
      final json = {
        'id': 'photo-123',
        'contest_id': 'contest-456',
        'user_id': 'user-789',
        'storage_path': 'contests/contest-456/photo-123.jpg',
        'meta_data': {'width': 1920, 'height': 1080, 'camera': 'iPhone 14'},
        'vote_count': 42,
        'created_at': '2024-06-15T14:30:00Z',
      };

      final photo = Photo.fromJson(json);

      expect(photo.id, 'photo-123');
      expect(photo.contestId, 'contest-456');
      expect(photo.userId, 'user-789');
      expect(photo.storagePath, 'contests/contest-456/photo-123.jpg');
      expect(photo.metaData, {
        'width': 1920,
        'height': 1080,
        'camera': 'iPhone 14',
      });
      expect(photo.voteCount, 42);
      expect(photo.createdAt, DateTime.parse('2024-06-15T14:30:00Z'));
    });

    test('fromJson handles null metadata', () {
      final json = {
        'id': 'photo-456',
        'contest_id': 'contest-789',
        'user_id': 'user-101',
        'storage_path': 'contests/contest-789/photo-456.jpg',
        'meta_data': null,
        'vote_count': 0,
        'created_at': '2024-06-16T10:00:00Z',
      };

      final photo = Photo.fromJson(json);

      expect(photo.metaData, null);
    });

    test('fromJson defaults vote count to 0 when null', () {
      final json = {
        'id': 'photo-789',
        'contest_id': 'contest-101',
        'user_id': 'user-202',
        'storage_path': 'contests/contest-101/photo-789.jpg',
        'vote_count': null,
        'created_at': '2024-06-17T08:00:00Z',
      };

      final photo = Photo.fromJson(json);

      expect(photo.voteCount, 0);
    });

    test('toJson serializes Photo correctly', () {
      final photo = Photo(
        id: 'photo-serialized',
        contestId: 'contest-test',
        userId: 'user-test',
        storagePath: 'test/path.jpg',
        metaData: {'key': 'value'},
        voteCount: 10,
        createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
      );

      final json = photo.toJson();

      expect(json['id'], 'photo-serialized');
      expect(json['contest_id'], 'contest-test');
      expect(json['user_id'], 'user-test');
      expect(json['storage_path'], 'test/path.jpg');
      expect(json['meta_data'], {'key': 'value'});
      expect(json['vote_count'], 10);
      expect(json['created_at'], '2024-01-01T12:00:00.000Z');
    });

    test('toJson handles null metadata', () {
      final photo = Photo(
        id: 'photo-no-meta',
        contestId: 'contest-test',
        userId: 'user-test',
        storagePath: 'test/path.jpg',
        metaData: null,
        voteCount: 0,
        createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
      );

      final json = photo.toJson();

      expect(json['meta_data'], null);
    });

    test('fromJson and toJson roundtrip preserves data', () {
      final originalJson = {
        'id': 'photo-roundtrip',
        'contest_id': 'contest-roundtrip',
        'user_id': 'user-roundtrip',
        'storage_path': 'roundtrip/path.jpg',
        'meta_data': {'test': 'data', 'number': 123},
        'vote_count': 5,
        'created_at': '2024-06-20T15:45:30Z',
      };

      final photo = Photo.fromJson(originalJson);
      final serializedJson = photo.toJson();

      expect(serializedJson['id'], originalJson['id']);
      expect(serializedJson['contest_id'], originalJson['contest_id']);
      expect(serializedJson['user_id'], originalJson['user_id']);
      expect(serializedJson['storage_path'], originalJson['storage_path']);
      expect(serializedJson['meta_data'], originalJson['meta_data']);
      expect(serializedJson['vote_count'], originalJson['vote_count']);
      // Note: DateTime serialization might differ slightly in format but represents same instant
      expect(
        DateTime.parse(serializedJson['created_at'] as String),
        DateTime.parse(originalJson['created_at'] as String),
      );
    });

    test('constructor sets default vote count to 0', () {
      final photo = Photo(
        id: 'photo-default',
        contestId: 'contest-default',
        userId: 'user-default',
        storagePath: 'default/path.jpg',
        createdAt: DateTime.now(),
      );

      expect(photo.voteCount, 0);
    });
  });
}
