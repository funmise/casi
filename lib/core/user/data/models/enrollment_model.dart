import 'package:casi/core/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casi/core/user/domain/entities/enrollment.dart';

class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.uid,
    required super.clinicId,
    required super.status,
    super.ethicsVersion,
    super.ethicsAcceptedAt,
  });

  factory EnrollmentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    EnrollmentStatus status;
    switch ((data['status'] as String)) {
      case 'active':
        status = EnrollmentStatus.active;
        break;
      case 'suspended':
        status = EnrollmentStatus.suspended;
        break;
      default:
        status = EnrollmentStatus.awaitingEthics;
    }

    final ethicsAcceptedAt = data['ethicsAcceptedAt'];
    return EnrollmentModel(
      uid: doc.id,
      clinicId: data['clinicId'] as String,
      status: status,
      ethicsVersion: data['ethicsVersion'] as String?,
      ethicsAcceptedAt: ethicsAcceptedAt is Timestamp
          ? ethicsAcceptedAt.toDate()
          : null,
    );
  }

  factory EnrollmentModel.empty() =>
      const EnrollmentModel(uid: '', clinicId: '', status: null);
}
