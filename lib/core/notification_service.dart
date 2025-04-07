import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    await _requestPermission();

    // Setup message handlers

    // Get FCM token
    final token = await _messaging.getToken();
     if (token != null) {
        String deviceId = await getDeviceId();
    await FirebaseFirestore.instance.collection('users').doc(deviceId).set(
      {"fcm_token": token,"last_active": DateTime.now(),},
      SetOptions(merge: true), 
    );
    print("FCM Token saved: $token");
  }
  }
  Future<String> getDeviceId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('device_id');

  if (deviceId == null) {
    deviceId = const Uuid().v4(); // Generate UUID
    await prefs.setString('device_id', deviceId);
  }

  return deviceId;
}

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    // android setup
   

    
    // ios setup
    // final initializationSettingsDarwin = DarwinInitializationSettings(
    //   onDidReceiveLocalNotification: (id, title, body, payload) async {
    //     // Handle iOS foreground notification
    //   },
    // );

  


  


/*************  ✨ Windsurf Command ⭐  *************/
  /// Handles a background message by checking the type of message and
  /// performing an appropriate action. If the message is a chat message,
  /// it opens the chat screen. Otherwise, it does nothing.
/*******  d742f285-7215-4680-954c-d8ee07fd6a25  *******/  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      // open chat screen
    }
  }
  }
}