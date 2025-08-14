import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/auth/domain/entities/user.dart';
import 'package:casi/features/auth/domain/usecases/get_current_user.dart';
import 'package:casi/features/auth/domain/usecases/google_sign_in.dart';
import 'package:casi/features/auth/domain/usecases/sign_out.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleSignInUC _googleSignIn;
  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;

  AuthBloc({
    required GoogleSignInUC googleSignIn,
    required GetCurrentUser getCurrentUser,
    required SignOut signOut,
  }) : _googleSignIn = googleSignIn,
       _getCurrentUser = getCurrentUser,
       _signOut = signOut,
       super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthGoogleRequested>(_onGoogle);
    on<AuthSignedOut>(_onSignOut);
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _getCurrentUser(NoParams());
    res.fold(
      (f) => emit(AuthFailure(f.message)),
      (u) =>
          u == null ? emit(AuthUnauthenticated()) : emit(AuthAuthenticated(u)),
    );
  }

  Future<void> _onGoogle(AuthGoogleRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _googleSignIn(NoParams());
    res.fold(
      (f) => emit(AuthFailure(f.message)),
      (u) => emit(AuthAuthenticated(u)),
    );
  }

  Future<void> _onSignOut(AuthSignedOut e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _signOut(NoParams());
    res.fold(
      (f) => emit(AuthFailure(f.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
