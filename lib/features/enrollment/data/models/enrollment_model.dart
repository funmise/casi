import 'package:casi/core/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casi/features/enrollment/domain/entities/enrollment.dart';

class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.uid,
    required super.clinicId,
    required super.status,
    super.ethicsVersion,
    super.ethicsAcceptedAt,
    super.avgDogsPerWeek,
  });

  factory EnrollmentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    EnrollmentStatus status;
    switch ((d['status'] as String)) {
      case 'active':
        status = EnrollmentStatus.active;
        break;
      case 'suspended':
        status = EnrollmentStatus.suspended;
        break;
      default:
        status = EnrollmentStatus.awaitingEthics;
    }

    final ts = d['ethicsAcceptedAt'];
    return EnrollmentModel(
      uid: doc.id,
      clinicId: d['clinicId'] as String,
      status: status,
      ethicsVersion: d['ethicsVersion'] as String?,
      ethicsAcceptedAt: ts is Timestamp ? ts.toDate() : null,
      avgDogsPerWeek: (d['avgDogsPerWeek'] as num?)?.toInt(),
    );
  }
}
