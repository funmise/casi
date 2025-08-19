import 'package:casi/core/user/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    super.name,
    super.createdAt,
  });

  factory UserModel.fromFirebaseUser(fa.User user) => UserModel(
    id: user.uid,
    email: user.email ?? '',
    // may be null the very first Apple login; Google usually sets it
    name: user.displayName,
    createdAt: user.metadata.creationTime,
  );
}
