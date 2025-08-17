enum ClinicStatus { pending, active, blocked }

class Clinic {
  final String id;
  final String name;
  final String? province;
  final String? city;
  final int? avgDogsPerWeek;
  final ClinicStatus status;
  final DateTime createdAt;

  const Clinic({
    required this.id,
    required this.name,
    this.province,
    this.city,
    this.avgDogsPerWeek,
    required this.status,
    required this.createdAt,
  });
}
