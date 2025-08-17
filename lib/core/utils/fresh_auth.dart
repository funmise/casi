// Top-level helper: force-refresh the cached Firebase user.
// If the user was deleted/disabled server-side, this will fail and we sign out.
import 'package:firebase_auth/firebase_auth.dart';

Future<void> ensureFreshAuth() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await user.getIdToken(true); // force refresh token
    } on FirebaseAuthException {
      await FirebaseAuth.instance.signOut(); // drop stale session
    }
  }
}
