import 'package:casi/core/user/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.email,
    super.name,
    super.userCreatedAt,
    super.enrollmentStatus,
    super.ethicsVersion,
    super.ethicsAcceptedAt,
    super.clinicId,
    super.clinicName,
    super.clinicProvince,
    super.clinicCity,
    super.clinicStatus,
  });
}
