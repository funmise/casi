import 'package:casi/core/enums.dart';

class Clinic {
  final String id;
  final String name;
  final String? province;
  final String? city;
  final ClinicStatus? status;
  final DateTime? createdAt;

  const Clinic({
    required this.id,
    required this.name,
    this.province,
    this.city,
    required this.status,
    this.createdAt,
  });
}
