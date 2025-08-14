import 'package:casi/core/error/failures.dart';
import 'package:casi/features/auth/domain/entities/user.dart';

import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User?>> currentUser();
  Future<Either<Failure, void>> signOut();
}
