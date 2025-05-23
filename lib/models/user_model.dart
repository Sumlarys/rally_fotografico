// lib/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String role; // "administrator" or "participant"

  UserModel({
    required this.id,
    required this.email,
    required this.role,
  });
}
