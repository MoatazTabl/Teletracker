import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  // Static callback to trigger jumpToMessage
  static void Function(int msgId)? onMessageReceived;

  // Store msg_id if callback isn't set yet (e.g., app starting)
  int? _pendingMsgId;

  Future<void> initialize() async {
    await _requestPermission();
    await _setupMessageHandlers();

    final token = await _messaging.getToken();
    if (token != null) {
      String deviceId = await getDeviceId();
      await FirebaseFirestore.instance.collection('users').doc(deviceId).set({
        "fcm_token": token,
        "last_active": DateTime.now(),
      }, SetOptions(merge: true));
      print("FCM Token saved: $token");

      _messaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        String deviceId = await getDeviceId();
        await FirebaseFirestore.instance.collection('users').doc(deviceId).set({
          "fcm_token": newToken,
          "last_active": DateTime.now(),
        }, SetOptions(merge: true));
      });
    }
  }

  Future<String> getDeviceId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_notification',
    );
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!) as Map<String, dynamic>;
            _handleMessageData(data);
          } catch (e) {
            print('Error handling notification response: $e');
          }
        }
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    // Handle message data first
    _handleMessageData(message.data);

    // Show notification if available
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      try {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
                  'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_notification',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      } catch (e) {
        print('Error showing notification: $e');
      }
    }
  }

  void _handleMessageData(Map<String, dynamic> data) {
 print("Handling message data...$data");
  if (data.containsKey('msg_id')) {
  
  


    final msgId = int.tryParse(data["msg_id"]);
    print("Parsed msgId: $msgId");
      
      if (msgId != null) {
        print("Received msg_id: $msgId");
        if (onMessageReceived != null) {
          onMessageReceived!(msgId);
        } else {
          _pendingMsgId = msgId;
          print("Callback not set, storing msg_id: $msgId");
        }
      }
    }
  }


  Future<void> _setupMessageHandlers() async {
    // Foreground: Trigger callback immediately
    FirebaseMessaging.onMessage.listen(showNotification);

    // Terminated: Check initial message and store if callback not set
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleMessageData(initialMessage.data);

    // Background: Trigger callback or store if not set
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleMessageData(message.data),
    );
  }

  // Method to check and trigger pending message after callback is set
  void checkPendingMessage() {
    if (_pendingMsgId != null && onMessageReceived != null) {
      print("Triggering pending msg_id: $_pendingMsgId");
      onMessageReceived!(_pendingMsgId!);
      _pendingMsgId = null; // Clear after triggering
    }
  }
}
