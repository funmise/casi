import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/auth/domain/repositories/auth_repository.dart';

class SignOut implements IsSignOut {
  final AuthRepository repo;
  SignOut(this.repo);
  @override
  Future<Either<Failure, void>> call(NoParams _) async => await repo.signOut();
}
