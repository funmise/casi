import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccount implements IsDeleteAccount {
  final AuthRepository repo;
  DeleteAccount(this.repo);
  @override
  Future<Either<Failure, void>> call(NoParams params) async =>
      await repo.deleteAccount();
}
