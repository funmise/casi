import 'dart:async';
import 'package:casi/core/push/push_token_uploader.dart';
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
  final IsDeleteAccount _deleteAccount;

  StreamSubscription<Either<Failure, ({UserProfile? user, bool fromCache})>>?
  _sub;

  // guard to suppress authed frames during deletion
  bool _isDeleting = false;

  UserCubit({
    required WatchUser watch,
    required IsSignOut signOut,
    required IsDeleteAccount deleteAccount,
  }) : _watch = watch,
       _signOut = signOut,
       _deleteAccount = deleteAccount,
       super(UserInitial());

  void _subscribe() {
    emit(UserLoading());
    _sub?.cancel();

    _sub = _watch(NoParams()).listen((res) {
      //  Early exit if we're in delete mode
      if (_isDeleting) {
        return; // don't emit any states
      }
      res.fold((failure) => emit(UserError(failure.message)), (payload) {
        final user = payload.user;
        if (user == null) {
          emit(UserUnauthenticated());
        } else {
          emit(UserReady(user, fromCache: payload.fromCache));
        }
      });
    }, onError: (e, __) => emit(UserError(e.toString())));
  }

  Future<void> signOut() async {
    emit(UserLoading());
    await PushTokenUploader.dispose();
    final res = await _signOut(NoParams());
    res.match((f) => emit(UserError(f.message)), (_) {
      // Don’t emit here. Firebase Auth will sign out,
      // authStateChanges() => null, and the watch() stream
      // will drive this cubit to UserUnauthenticated automatically.
    });
  }

  Future<void> deleteAccount() async {
    _isDeleting = true;
    emit(UserDeleting());

    await PushTokenUploader.dispose();
    final res = await _deleteAccount(NoParams());
    res.match(
      (f) async {
        _isDeleting = false;
        emit(UserError(f.message));
        await signOut();
      },
      (_) {
        _isDeleting = false;
        emit(UserUnauthenticated());
      },
    );
  }

  // to restart the stream manually
  void resubscribe() => _subscribe();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
