import 'package:fpdart/fpdart.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/features/enrollment/domain/entities/enrollment.dart';
import 'package:casi/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetEnrollment implements UseCase<Enrollment, String> {
  final EnrollmentRepository repo;
  GetEnrollment(this.repo);

  @override
  Future<Either<Failure, Enrollment>> call(String uid) =>
      repo.getEnrollment(uid);
}
