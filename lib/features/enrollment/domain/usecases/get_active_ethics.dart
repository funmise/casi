import 'package:fpdart/fpdart.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/features/enrollment/domain/entities/ethics.dart';
import 'package:casi/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetActiveEthics implements UseCase<Ethics, NoParams> {
  final EnrollmentRepository repo;
  GetActiveEthics(this.repo);

  @override
  Future<Either<Failure, Ethics>> call(NoParams _) => repo.getActiveEthics();
}
