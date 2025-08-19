import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:casi/core/error/exceptions.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/user/domain/entities/user_profile.dart';
import 'package:casi/core/user/domain/repositories/user_repository.dart';
import 'package:casi/core/user/data/data_sources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remote;

  // One shared stream for the whole app.
  // Both UserCubit and AuthBloc will subscribe to THIS, avoiding double reads.
  late final Stream<Either<Failure, UserProfile?>> _shared = _buildShared();

  UserRepositoryImpl(this._remote);

  Stream<Either<Failure, UserProfile?>> _buildShared() {
    try {
      return _remote
          .watch()
          .map<Either<Failure, UserProfile?>>((p) => Right(p))
          // Turn async errors into a value (Left) before completion.
          .onErrorReturnWith((error, stack) {
            if (error is ServerException) {
              return Left(Failure(error.message));
            }
            return Left(Failure('Unexpected repository error: $error'));
          })
          // Multicast + cache the latest value for late subscribers.
          .shareReplay(maxSize: 1);
    } on ServerException catch (e) {
      // Synchronous error before stream creation → one-item error stream.
      return Stream.value(Left(Failure(e.message)));
    } catch (e) {
      return Stream.value(Left(Failure('Unexpected repository error: $e')));
    }
  }

  @override
  Stream<Either<Failure, UserProfile?>> watch() => _shared;
}
