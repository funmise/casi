import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/auth/domain/entities/user.dart';
import 'package:casi/features/auth/domain/repositories/auth_repository.dart';

import 'package:fpdart/fpdart.dart';

class GetCurrentUser implements UseCase<User?, NoParams> {
  final AuthRepository repo;
  GetCurrentUser(this.repo);
  @override
  Future<Either<Failure, User?>> call(NoParams _) async =>
      await repo.currentUser();
}
