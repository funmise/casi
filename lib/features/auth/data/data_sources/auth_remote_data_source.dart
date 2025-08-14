import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import 'package:casi/core/error/exceptions.dart';
import 'package:casi/features/auth/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel?> currentUser();
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fa.FirebaseAuth _auth;
  final gsi.GoogleSignIn _google;

  AuthRemoteDataSourceImpl({
    required fa.FirebaseAuth auth,
    required gsi.GoogleSignIn google,
  }) : _auth = auth,
       _google = google;

  UserModel _map(fa.User u) => UserModel(
    id: u.uid,
    email: u.email ?? '',
    name: u
        .displayName, // may be null the very first Apple login; Google usually sets it
    createdAt: u.metadata.creationTime,
  );

  @override
  Future<UserModel?> currentUser() async {
    final u = _auth.currentUser;
    return u == null ? null : _map(u);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // 1) Interactive sign-in (throws on cancel/misconfig)
      final gsi.GoogleSignInAccount account = await _google.authenticate();

      // 2) Get tokens (v7: synchronous container, no await)
      final gsi.GoogleSignInAuthentication authTokens = account.authentication;

      final String? idToken = authTokens.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ServerException('Missing Google ID token.');
      }

      // 3) Firebase sign-in (accessToken no longer required)
      final fa.OAuthCredential credential = fa.GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final fa.UserCredential cred = await _auth.signInWithCredential(
        credential,
      );
      final fa.User? u = cred.user;
      if (u == null) throw ServerException('No user returned');

      return _map(u);
    } on gsi.GoogleSignInException catch (e) {
      // v7: use code + optional description
      final code = e.code; // GoogleSignInExceptionCode
      String msg;
      if (code == gsi.GoogleSignInExceptionCode.canceled) {
        msg = 'Sign-in cancelled.';
      } else if (code == gsi.GoogleSignInExceptionCode.interrupted) {
        msg = 'Network error during Google sign-in.';
      } else {
        final extra = (e.description == null || e.description!.isEmpty)
            ? ''
            : ': ${e.description}';
        msg = 'Google sign-in failed (${code.name}$extra).';
      }
      throw ServerException(msg);
    } on fa.FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Auth error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}
