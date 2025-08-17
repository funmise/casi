import 'package:fpdart/fpdart.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/features/enrollment/domain/repositories/enrollment_repository.dart';

class SetEnrollmentClinic implements UseCase<void, ParamsSetClinic> {
  final EnrollmentRepository repo;
  SetEnrollmentClinic(this.repo);

  @override
  Future<Either<Failure, void>> call(ParamsSetClinic p) {
    return repo.setEnrollmentClinic(
      uid: p.uid,
      clinicId: p.clinicId,
      avgDogsPerWeek: p.avgDogsPerWeek,
    );
  }
}

class ParamsSetClinic {
  final String uid;
  final String clinicId;
  final int? avgDogsPerWeek;
  ParamsSetClinic({
    required this.uid,
    required this.clinicId,
    this.avgDogsPerWeek,
  });
}
