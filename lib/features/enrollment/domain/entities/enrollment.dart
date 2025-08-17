enum EnrollmentStatus { awaitingEthics, active, suspended }

class Enrollment {
  final String uid;
  final String clinicId;
  final EnrollmentStatus status;
  final String? ethicsVersion;
  final DateTime? ethicsAcceptedAt;
  final int? avgDogsPerWeek;

  const Enrollment({
    required this.uid,
    required this.clinicId,
    required this.status,
    this.ethicsVersion,
    this.ethicsAcceptedAt,
    this.avgDogsPerWeek,
  });
}
