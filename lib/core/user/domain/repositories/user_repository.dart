import 'package:casi/core/error/failures.dart';
import 'package:casi/core/user/domain/entities/user_profile.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class UserRepository {
  Stream<Either<Failure, UserProfile?>> watch();
}
