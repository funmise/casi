import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/user/domain/entities/user_profile.dart';
import 'package:casi/core/user/domain/repositories/user_repository.dart';
import 'package:fpdart/fpdart.dart';

class WatchUser
    implements StreamUseCase<({UserProfile? user, bool fromCache}), NoParams> {
  final UserRepository _repo;
  WatchUser(this._repo);

  @override
  Stream<Either<Failure, ({UserProfile? user, bool fromCache})>> call(
    NoParams params,
  ) {
    return _repo.watch();
  }
}
