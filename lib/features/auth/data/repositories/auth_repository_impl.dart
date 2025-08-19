import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/exceptions.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/user/domain/entities/user.dart';
import 'package:casi/features/auth/domain/repositories/auth_repository.dart';
import 'package:casi/features/auth/data/data_sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  AuthRepositoryImpl(this.remote);
  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final u = await remote.signInWithGoogle();
      return right(u);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remote.signOut();
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
