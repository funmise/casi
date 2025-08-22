import 'package:casi/core/enums.dart';

class Enrollment {
  final String uid;
  final String clinicId;
  final EnrollmentStatus? status;
  final String? ethicsVersion;
  final DateTime? ethicsAcceptedAt;

  const Enrollment({
    required this.uid,
    required this.clinicId,
    required this.status,
    this.ethicsVersion,
    this.ethicsAcceptedAt,
  });
}
