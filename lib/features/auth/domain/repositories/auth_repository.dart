import 'package:casi/core/error/failures.dart';
import 'package:casi/core/user/domain/entities/user.dart';

import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> deleteAccount();
}
