class User {
  final String id;
  final String email;
  final String? name;
  final DateTime? createdAt;

  User({required this.id, required this.email, this.name, this.createdAt});
}
