import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_notification_app/firebase_options.dart';
import 'package:test_notification_app/models/result.dart';
import 'package:test_notification_app/services/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionState { granted, denied, restricted, unknown }

// this service is responsible for handling notifications
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  if (message.notification != null) {
    final pref = await SharedPreferences.getInstance();
    await pref.remove('scheduledTime');
    notificationService.showNotification(message.notification!);
  }
}

class NotificationService {
  final _notificationPermissionsChanges = BehaviorSubject<PermissionStatus?>();

  final _scheduledTime = BehaviorSubject<DateTime?>();
  Stream<DateTime?> get scheduledTime => _scheduledTime.stream;

  Stream<PermissionStatus?> get notificationPermissionsChanges =>
      _notificationPermissionsChanges.stream;

  late final FlutterLocalNotificationsPlugin _localNotificationsPlugin;
  late final FirebaseMessaging _messaging;
  String? _deviceToken;

  String? get deviceToken => _deviceToken;

  Future<void> initialize() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove('scheduledTime');

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _messaging = FirebaseMessaging.instance;

      _deviceToken = await _messaging.getToken();
      loggerService.debug('FCM Token: $_deviceToken');

      final androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      final initSettings = InitializationSettings(android: androidSettings);
      _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await _localNotificationsPlugin.initialize(initSettings);

      _setupMessageListeners();
    } catch (e) {
      loggerService.error('Failed to initialize Firebase: $e');
    }
  }

  void _setupMessageListeners() {
    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      loggerService
          .debug('Received a message in the foreground: ${message.messageId}');
      if (message.notification != null) {
        _scheduledTime.add(null);

        final pref = await SharedPreferences.getInstance();
        await pref.remove('scheduledTime');

        showNotification(message.notification!);
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<Result<bool>> scheduleNotification(
    String title,
    String message,
    DateTime scheduledTime,
  ) async {
    try {
      final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
      final scheduledTimeString = formatter.format(scheduledTime.toUtc());

      final projectId = dotenv.env['PROJECT_ID'];
      final location = dotenv.env['LOCATION'];

      final url = Uri.parse(
          'https://$location-$projectId.cloudfunctions.net/scheduleNotification');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'title': title,
        'body': message,
        'token': deviceToken,
        'scheduledTime': scheduledTimeString
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        loggerService
            .debug('Notification scheduled to be sent at $scheduledTimeString');
        _scheduledTime.add(scheduledTime);
        final pref = await SharedPreferences.getInstance();
        await pref.setString('scheduledTime', scheduledTimeString);

        return Result.success(true);
      } else {
        loggerService.error(
          'Failed to schedule notification: ${response.statusCode}, ${response.body}',
        );
        return Result.failure('Failed to schedule notification');
      }
    } catch (e) {
      loggerService.error('Error scheduling notification: $e');
      return Result.failure('Error scheduling notification');
    }
  }

  void showNotification(RemoteNotification notification) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'regular_event_notification_id',
      'regular event notification',
      importance: Importance.max,
      priority: Priority.max,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    final random = Random();

    _localNotificationsPlugin.show(
      random.nextInt(1000000),
      notification.title,
      notification.body,
      platformDetails,
    );
  }

  Future<Result<bool>> requestPermission() async {
    try {
      NotificationSettings? settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final status = getPermissionbyAuthStatus(settings.authorizationStatus);

      _notificationPermissionsChanges.add(status);

      loggerService.info('Notification permission status: $status');

      return Result.success(status == PermissionStatus.granted);
    } catch (e) {
      _notificationPermissionsChanges.add(PermissionStatus.denied);
      loggerService.error('Error requesting permissions: $e');
      return Result.failure('Error requesting notification permissions');
    }
  }

  void handleScheduleTime() async {
    final pref = await SharedPreferences.getInstance();
    await pref.reload();
    final scheduledTimeString = pref.getString('scheduledTime');
    if (scheduledTimeString != null) {
      final scheduledTime = DateTime.parse(scheduledTimeString);
      _scheduledTime.add(scheduledTime);
    } else {
      _scheduledTime.add(null);
    }
  }

  Future<Result<bool>> checkPermissions() async {
    try {
      final settings = await _messaging.getNotificationSettings();

      final status = getPermissionbyAuthStatus(settings.authorizationStatus);

      _notificationPermissionsChanges.add(status);

      loggerService.info('Notification permission status: $status');

      final granted = status == PermissionStatus.granted;

      return Result.success(granted);
    } catch (e) {
      _notificationPermissionsChanges.add(PermissionStatus.denied);
      loggerService.error('Error checking permissions: $e');
      return Result.failure('Error checking permissions $e');
    }
  }

  PermissionStatus getPermissionbyAuthStatus(AuthorizationStatus authStatus) {
    return switch (authStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        PermissionStatus.granted,
      _ => PermissionStatus.denied,
    };
  }

  void dispose() {
    _notificationPermissionsChanges.close();
  }
}
