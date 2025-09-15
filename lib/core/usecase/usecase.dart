import 'package:casi/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

abstract interface class StreamUseCase<SuccessType, Params> {
  Stream<Either<Failure, SuccessType>> call(Params params);
}

abstract interface class IsSignOut implements UseCase<void, NoParams> {
  @override
  Future<Either<Failure, void>> call(NoParams params);
}

abstract interface class IsDeleteAccount implements UseCase<void, NoParams> {
  @override
  Future<Either<Failure, void>> call(NoParams params);
}

class NoParams {}
