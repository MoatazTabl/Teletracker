import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';  // استيراد مكتبة awesome_notifications
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupAwesomeNotifications();  // استخدام setupAwesomeNotifications بدلاً من flutter_local_notifications
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  bool _isAwesomeNotificationsInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    await _requestPermission();

    // Setup message handlers
    await _setupMessageHandlers();

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      String deviceId = await getDeviceId();
      await FirebaseFirestore.instance.collection('users').doc(deviceId).set(
        {"fcm_token": token, "last_active": DateTime.now()},
        SetOptions(merge: true),
      );
      print("FCM Token saved: $token");
    }
  }

  Future<String> getDeviceId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      deviceId = const Uuid().v4();  // Generate UUID
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

  Future<void> setupAwesomeNotifications() async {
    if (_isAwesomeNotificationsInitialized) {
      return;
    }

    // إعداد الإشعارات لـ Android و iOS باستخدام awesome_notifications
    AwesomeNotifications().initialize(
      'resource://drawable/res_app_icon',  // أيقونة التطبيق
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic notifications',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
        )
      ],
    );
    _isAwesomeNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    // يمكنك تخصيص الإشعارات بناءً على محتوى الرسالة
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(1000),
        channelKey: 'basic_channel',
        title: message.notification?.title ?? "No Title",
        body: message.notification?.body ?? "No Body",
      ),
    );
  }

  Future<void> _setupMessageHandlers() async {
    // Message Handler for foreground
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    // Background message handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle when the app is opened from a terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      // يمكنك إضافة عملية فتح شاشة المحادثة هنا
    }
  }
}
