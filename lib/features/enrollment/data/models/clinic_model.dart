import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casi/features/enrollment/domain/entities/clinic.dart';

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
    final d = doc.data()!;
    ClinicStatus status;
    switch ((d['status'] as String)) {
      case 'active':
        status = ClinicStatus.active;
        break;
      case 'blocked':
        status = ClinicStatus.blocked;
        break;
      default:
        status = ClinicStatus.pending;
    }
    final ts = d['createdAt'];
    return ClinicModel(
      id: doc.id,
      name: d['name'] as String,
      province: d['province'] as String?,
      city: d['city'] as String?,
      avgDogsPerWeek: (d['avgDogsPerWeek'] as num?)?.toInt(),
      status: status,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMapForCreate() => {
    'name': name,
    'nameLower': name.toLowerCase(),
    'province': province,
    'city': city,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  };
}
