import 'package:casi/core/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casi/core/user/domain/entities/clinic.dart';

class ClinicModel extends Clinic {
  const ClinicModel({
    required super.id,
    required super.name,
    super.province,
    super.city,
    super.avgDogsPerWeek,
    required super.status,
    required super.createdAt,
  });

  factory ClinicModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    ClinicStatus status;
    switch ((data['status'] as String)) {
      case 'active':
        status = ClinicStatus.active;
        break;
      case 'blocked':
        status = ClinicStatus.blocked;
        break;
      default:
        status = ClinicStatus.pending;
    }
    final createdAt = data['createdAt'];
    return ClinicModel(
      id: doc.id,
      name: data['name'] as String,
      province: data['province'] as String?,
      city: data['city'] as String?,
      avgDogsPerWeek: (data['avgDogsPerWeek'] as num?)?.toInt(),
      status: status,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  factory ClinicModel.empty() =>
      const ClinicModel(id: '', name: '', status: null, createdAt: null);
}
