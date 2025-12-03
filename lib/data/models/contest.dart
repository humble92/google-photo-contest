enum ContestStatus { draft, active, ended }

enum VotingType { like, stars, categories }

class Contest {
  final String id;
  final String hostUserId;
  final String title;
  final String? description;
  final ContestStatus status;
  final DateTime? startAt;
  final DateTime? endAt;
  final VotingType votingType;
  final bool showVoteCounts;
  final DateTime createdAt;

  Contest({
    required this.id,
    required this.hostUserId,
    required this.title,
    this.description,
    required this.status,
    this.startAt,
    this.endAt,
    required this.votingType,
    required this.showVoteCounts,
    required this.createdAt,
  });

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
      id: json['id'],
      hostUserId: json['host_user_id'],
      title: json['title'],
      description: json['description'],
      status: ContestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContestStatus.draft,
      ),
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'])
          : null,
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
      votingType: VotingType.values.firstWhere(
        (e) => e.name == json['voting_type'],
        orElse: () => VotingType.like,
      ),
      showVoteCounts: json['show_vote_counts'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
