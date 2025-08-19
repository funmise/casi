import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/user/domain/entities/user_profile.dart';
import 'package:casi/core/user/domain/usecases/watch_user.dart';
import 'package:casi/core/user/cubit/user_state.dart';

class UserCubit extends Cubit<UserState> {
  final WatchUser _watch;
  final IsSignOut _signOut;

  StreamSubscription<Either<Failure, UserProfile?>>? _sub;

  UserCubit({required WatchUser watch, required IsSignOut signOut})
    : _watch = watch,
      _signOut = signOut,
      super(UserInitial()) {
    _subscribe();
  }

  void _subscribe() {
    emit(UserLoading());
    _sub?.cancel();

    _sub = _watch(NoParams()).listen(
      (res) => res.fold(
        (failure) => emit(UserError(failure.message)),
        (profile) => profile == null
            ? emit(UserUnauthenticated())
            : emit(UserReady(profile)),
      ),
      onError: (e, __) => emit(UserError(e.toString())),
    );
  }

  Future<void> signOut() async {
    final res = await _signOut(NoParams());
    res.match((f) => emit(UserError(f.message)), (_) {
      // Don’t emit here. Firebase Auth will sign out,
      // authStateChanges() => null, and the watch() stream
      // will drive this cubit to UserUnauthenticated automatically.
    });
  }

  //to restart the stream manually.
  void resubscribe() => _subscribe();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
