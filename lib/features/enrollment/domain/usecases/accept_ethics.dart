import 'package:fpdart/fpdart.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/features/enrollment/domain/repositories/enrollment_repository.dart';

class AcceptEthics implements UseCase<void, ParamsAcceptEthics> {
  final EnrollmentRepository repo;
  AcceptEthics(this.repo);

  @override
  Future<Either<Failure, void>> call(ParamsAcceptEthics p) {
    return repo.acceptEthics(uid: p.uid, version: p.version);
  }
}

class ParamsAcceptEthics {
  final String uid;
  final String version;
  ParamsAcceptEthics({required this.uid, required this.version});
}
