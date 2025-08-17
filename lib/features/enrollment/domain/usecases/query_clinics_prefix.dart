import 'package:fpdart/fpdart.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/features/enrollment/domain/entities/clinic.dart';
import 'package:casi/features/enrollment/domain/repositories/enrollment_repository.dart';

class QueryClinicsPrefix implements UseCase<List<Clinic>, ParamsQueryClinic> {
  final EnrollmentRepository repo;
  QueryClinicsPrefix(this.repo);

  @override
  Future<Either<Failure, List<Clinic>>> call(ParamsQueryClinic p) {
    return repo.queryClinicsPrefix(p.query, limit: p.limit);
  }
}

class ParamsQueryClinic {
  final String query;
  final int? limit;
  ParamsQueryClinic(this.query, {this.limit});
}
