import 'package:casi/features/auth/domain/entities/user.dart' as domain;

class UserModel extends domain.User {
  UserModel({
    required super.id,
    required super.email,
    super.name,
    super.createdAt,
  });

  factory UserModel.fromFirebaseUser(Object firebaseUser) {
    // typed minimally to avoid adding firebase_auth types in domain
    // We'll map in the datasource
    throw UnimplementedError("Use the mapper in datasource.");
  }
}
