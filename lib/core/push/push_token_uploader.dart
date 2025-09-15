import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushTokenUploader {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static StreamSubscription<String>? _tokenSub;

  static Future<void> ensureUploaded() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // iOS: skip if APNs token doesn't exist (simulator / no APNs config)
    if (Platform.isIOS) {
      final apns = await _messaging.getAPNSToken();
      if (apns == null) return;
    }

    final token = await _messaging.getToken();
    if (token == null) return;

    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : Platform.isMacOS
        ? 'macos'
        : Platform.isWindows
        ? 'windows'
        : Platform.isLinux
        ? 'linux'
        : 'unknown';

    await _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'platform': platform,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    //replace any previous listener so no stale-UID callback remains.
    await _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen((newToken) async {
      final freshUid = _auth.currentUser?.uid; // fetch at callback time
      if (freshUid == null) return;

      await _db
          .collection('users')
          .doc(freshUid)
          .collection('fcmTokens')
          .doc(newToken)
          .set({
            'platform': platform,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    });
  }

  /// Call before signOut/delete to remove any listener that captured an old UID.
  static Future<void> dispose() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
  }
}
