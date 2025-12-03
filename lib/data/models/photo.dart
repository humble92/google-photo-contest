class Photo {
  final String id;
  final String contestId;
  final String userId;
  final String storagePath;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.contestId,
    required this.userId,
    required this.storagePath,
    this.metadata,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      contestId: json['contest_id'] as String,
      userId: json['user_id'] as String,
      storagePath: json['storage_path'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contest_id': contestId,
      'user_id': userId,
      'storage_path': storagePath,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
