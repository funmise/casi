import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/user/domain/entities/user.dart';
import 'package:casi/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class GoogleSignInUC implements UseCase<User, NoParams> {
  final AuthRepository repo;
  GoogleSignInUC(this.repo);
  @override
  Future<Either<Failure, User>> call(NoParams _) async =>
      await repo.signInWithGoogle();
}
