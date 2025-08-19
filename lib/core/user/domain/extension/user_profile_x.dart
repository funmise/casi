// user_profile_x.dart
import 'package:casi/core/user/domain/entities/user.dart';
import 'package:casi/core/user/domain/entities/user_profile.dart';

extension UserProfileX on UserProfile {
  User toUser() =>
      User(id: uid, email: email, name: name, createdAt: userCreatedAt);
}
