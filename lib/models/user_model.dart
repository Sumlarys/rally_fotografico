class UserModel {
  final String id;
  final String email;
  final String? username;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      role: json['role'] as String,
    );
  }
}
