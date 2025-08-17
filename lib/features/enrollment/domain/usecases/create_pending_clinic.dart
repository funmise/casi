import 'package:fpdart/fpdart.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/features/enrollment/domain/entities/clinic.dart';
import 'package:casi/features/enrollment/domain/repositories/enrollment_repository.dart';

class CreatePendingClinic implements UseCase<Clinic, ParamsCreateClinic> {
  final EnrollmentRepository repo;
  CreatePendingClinic(this.repo);

  @override
  Future<Either<Failure, Clinic>> call(ParamsCreateClinic p) {
    return repo.createPendingClinic(p.name, province: p.province, city: p.city);
  }
}

class ParamsCreateClinic {
  final String name;
  final String? province;
  final String? city;
  ParamsCreateClinic(this.name, {this.province, this.city});
}
