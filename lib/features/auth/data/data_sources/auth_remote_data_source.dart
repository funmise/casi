import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import 'package:casi/core/error/exceptions.dart';
import 'package:casi/core/user/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fa.FirebaseAuth _auth;
  final gsi.GoogleSignIn _google;

  AuthRemoteDataSourceImpl({
    required fa.FirebaseAuth auth,
    required gsi.GoogleSignIn google,
  }) : _auth = auth,
       _google = google;

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final gsi.GoogleSignInAccount account = await _google.authenticate();

      final gsi.GoogleSignInAuthentication authTokens = account.authentication;

      final String? idToken = authTokens.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ServerException('Missing Google ID token.');
      }

      final fa.OAuthCredential credential = fa.GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final fa.UserCredential cred = await _auth.signInWithCredential(
        credential,
      );
      final fa.User? u = cred.user;
      if (u == null) throw ServerException('No user returned');

      return UserModel.fromFirebaseUser(u);
    } on gsi.GoogleSignInException catch (e) {
      final code = e.code;
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
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final u = _auth.currentUser;
      if (u == null) throw ServerException('Not signed in.');

      Future<void> reauthAndDelete() async {
        // Pick a provider; prefer the first entry (or check contains('google.com'))
        final providers = u.providerData.map((p) => p.providerId).toList();

        if (providers.contains('google.com')) {
          final p = fa.GoogleAuthProvider();
          // Optional, but helps force a fresh token/UI:
          p.setCustomParameters({'prompt': 'consent'});
          await u.reauthenticateWithProvider(p);
        } else if (providers.contains('apple.com')) {
          final p = fa.AppleAuthProvider();
          await u.reauthenticateWithProvider(p);
        } else {
          // Fallback – first provider entry
          final first = u.providerData.firstOrNull?.providerId ?? '';
          if (first == 'apple.com') {
            await u.reauthenticateWithProvider(fa.AppleAuthProvider());
          } else if (first == 'google.com') {
            await u.reauthenticateWithProvider(fa.GoogleAuthProvider());
          } else {
            throw ServerException(
              'Please sign in again and retry account deletion (recent login required).',
            );
          }
        }

        await u.delete();
      }

      try {
        await u.delete();
      } on fa.FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          await reauthAndDelete();
        } else {
          throw ServerException(e.message ?? 'Account deletion failed.');
        }
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Unexpected error during deletion: $e');
    }
  }
}
