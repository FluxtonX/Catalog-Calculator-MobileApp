class UserReport {
  final String id;
  final String userId;
  final String artistName;
  final String platform;
  final double estimatedValue;
  final DateTime createdAt;

  UserReport({
    required this.id,
    required this.userId,
    required this.artistName,
    required this.platform,
    required this.estimatedValue,
    required this.createdAt,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      artistName: json['artist_name'] as String,
      platform: json['platform'] as String,
      estimatedValue: (json['estimated_value'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'artist_name': artistName,
      'platform': platform,
      'estimated_value': estimatedValue,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
