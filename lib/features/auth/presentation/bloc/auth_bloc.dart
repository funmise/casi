import 'dart:async';

import 'package:casi/core/error/failures.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/user/domain/entities/user.dart';
import 'package:casi/core/user/domain/entities/user_profile.dart';
import 'package:casi/core/user/domain/extension/user_profile_x.dart';
import 'package:casi/core/user/domain/usecases/watch_user.dart';
import 'package:casi/features/auth/domain/usecases/google_sign_in.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleSignInUC _googleSignIn;
  //final GetCurrentUser _getCurrentUser;
  final IsSignOut _signOut;
  final WatchUser _watchUser;

  AuthBloc({
    required GoogleSignInUC googleSignIn,
    required IsSignOut signOut,
    required WatchUser watchUser,
  }) : _googleSignIn = googleSignIn,
       _signOut = signOut,
       _watchUser = watchUser,
       super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthGoogleRequested>(_onGoogle);
    on<AuthSignedOut>(_onSignOut);
  }

  // Starts watching the user stream and maps it to auth states.
  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Bloc manages the subscription; no manual StreamSubscription needed.
    await emit.forEach<Either<Failure, UserProfile?>>(
      _watchUser(NoParams()),
      onData: (either) => either.match(
        (f) => AuthFailure(f.message),
        (profile) => profile == null
            ? AuthUnauthenticated()
            : AuthAuthenticated(profile.toUser()),
      ),
      onError: (e, __) => AuthFailure(e.toString()),
    );
  }

  Future<void> _onGoogle(AuthGoogleRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _googleSignIn(NoParams());
    res.fold((f) => emit(AuthFailure(f.message)), (u) {
      // DO not emit(AuthAuthenticated(u));
      //Do nothing; WatchUser will emit Right(null) -> AuthUnauthenticated.
    });
  }

  Future<void> _onSignOut(AuthSignedOut e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _signOut(NoParams());
    res.fold((f) => emit(AuthFailure(f.message)), (_) {
      // DO not emit(AuthUnauthenticated());
      // Do nothing else; authStateChanges() -> WatchUser will emit
      // AuthAuthenticated automatically.
    });
  }
}
