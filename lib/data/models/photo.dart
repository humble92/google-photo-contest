class Photo {
  final String id;
  final String contestId;
  final String userId;
  final String storagePath;
  final Map<String, dynamic>? metaData;
  final int voteCount;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.contestId,
    required this.userId,
    required this.storagePath,
    this.metaData,
    this.voteCount = 0,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      contestId: json['contest_id'] as String,
      userId: json['user_id'] as String,
      storagePath: json['storage_path'] as String,
      metaData: json['meta_data'] as Map<String, dynamic>?,
      voteCount: json['vote_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contest_id': contestId,
      'user_id': userId,
      'storage_path': storagePath,
      'meta_data': metaData,
      'vote_count': voteCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
