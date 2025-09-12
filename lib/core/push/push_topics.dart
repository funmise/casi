import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

String _topicForQuarter(String qid) => 'survey_$qid';

class PushTopics {
  static final _fcm = FirebaseMessaging.instance;
  static String? _current;

  static Future<void> ensureSubscribed(String? quarterId) async {
    if (quarterId == null || quarterId.isEmpty) return;

    // iOS: if APNs token isn't available (simulator / not configured), bail out.
    if (Platform.isIOS) {
      await _fcm.requestPermission();
      final apns = await _fcm.getAPNSToken();
      if (apns == null) return; // avoid 'apns-token-not-set' on simulator
    }

    if (_current == quarterId) return; // already on it

    // leave previous
    if (_current != null && _current!.isNotEmpty && _current != quarterId) {
      await _fcm.unsubscribeFromTopic(_topicForQuarter(_current!));
      _current = null;
    }

    // join new
    await _fcm.requestPermission(); // no-op if already granted
    await _fcm.subscribeToTopic(_topicForQuarter(quarterId));
    _current = quarterId;
  }

  static Future<void> unsubscribeAll() async {
    if (_current != null && _current!.isNotEmpty) {
      await _fcm.unsubscribeFromTopic(_topicForQuarter(_current!));
      _current = null;
    }
  }
}
