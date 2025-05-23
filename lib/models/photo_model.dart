// lib/models/photo_model.dart

import 'package:hive/hive.dart';
part 'photo_model.g.dart';

@HiveType(typeId: 0)
class Photo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String status;

  @HiveField(4)
  final int votes;

  @HiveField(5)
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.userId,
    required this.url,
    required this.status,
    required this.votes,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        url: json['url'] as String,
        status: json['status'] as String? ?? 'pending',
        votes: json['votes'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Photo copyWith({int? votes}) {
    return Photo(
      id: id,
      userId: userId,
      url: url,
      status: status,
      votes: votes ?? this.votes,
      createdAt: createdAt,
    );
  }
}
