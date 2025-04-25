class Photo {
  final String id;
  final String userId;
  final String url;
  final String status;
  final int votes;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.userId,
    required this.url,
    required this.status,
    required this.votes,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      url: json['url'] as String,
      status: json['status'] as String,
      votes: json['votes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
