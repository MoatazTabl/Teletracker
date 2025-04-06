import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:teletracker/features/home_screen/home_screen.dart';
import 'package:teletracker/firebase_options.dart';
import 'dart:async';

import 'core/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter errors and send to Crashlytics
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Initialize Firebase with retry logic
  if (await initializeFirebaseWithRetry()) {
    try {
      // Initialize Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await NotificationService.instance.initialize();
      runApp(const MyApp());
    } catch (e, stack) {
      print('Failed to initialize services: $e');
      // Record the error to Crashlytics if it's available
      try {
        FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: 'Error during app initialization',
        );
      } catch (_) {
        // Ignore if Crashlytics isn't initialized yet
      }
      runApp(buildErrorApp('Failed to initialize services'));
    }
  } else {
    runApp(
      buildErrorApp('Failed to initialize Firebase after multiple attempts'),
    );
  }
}

/// Attempts to initialize Firebase with retry logic
/// Returns true if successful, false otherwise
Future<bool> initializeFirebaseWithRetry({
  int maxAttempts = 3,
  Duration delayBetweenAttempts = const Duration(seconds: 2),
}) async {
  int attempts = 0;

  while (attempts < maxAttempts) {
    try {
      attempts++;
      print(
        'Attempting to initialize Firebase (Attempt $attempts of $maxAttempts)',
      );

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      print('Firebase initialized successfully');
      return true;
    } catch (e, stack) {
      print('Firebase initialization failed: $e');

      if (attempts >= maxAttempts) {
        try {

          await FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason:
                'Firebase initialization failed after $maxAttempts attempts',
          );
        } catch (_) {
          // Ignore if Crashlytics isn't initialized yet
        }

        print(
          'Maximum attempts reached. Giving up on Firebase initialization.',
        );
        return false;
      }

      print('Retrying in ${delayBetweenAttempts.inSeconds} seconds...');
      await Future.delayed(delayBetweenAttempts);
    }
  }

  return false;
}

/// Builds an error app with the specified message
MaterialApp buildErrorApp(String errorMessage) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // In MyApp build method
    return MaterialApp(
      title: 'Telegram Messages',

      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MessagesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
