import 'package:casi/core/enums.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final DateTime? userCreatedAt;

  final EnrollmentStatus? enrollmentStatus;
  final String? ethicsVersion;
  final DateTime? ethicsAcceptedAt;

  final String? clinicId;
  final String? clinicName;
  final String? clinicProvince;
  final String? clinicCity;
  final ClinicStatus? clinicStatus;

  final String? activeSurveyQuarter;
  final String? activeSurveyStatus;

  const UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.userCreatedAt,
    this.enrollmentStatus,
    this.ethicsVersion,
    this.ethicsAcceptedAt,
    this.clinicId,
    this.clinicName,
    this.clinicProvince,
    this.clinicCity,
    this.clinicStatus,
    this.activeSurveyQuarter,
    this.activeSurveyStatus,
  });
}
