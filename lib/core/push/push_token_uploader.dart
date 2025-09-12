import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushTokenUploader {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> ensureUploaded() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // iOS: skip if APNs token doesn't exist (simulator / no APNs config)
    if (Platform.isIOS) {
      await _messaging.requestPermission();
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

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token);

    await ref.set({
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Keep Firestore up-to-date if the token ever rotates
    _messaging.onTokenRefresh.listen((newToken) async {
      final newRef = _db
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(newToken);

      await newRef.set({
        'platform': platform,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
