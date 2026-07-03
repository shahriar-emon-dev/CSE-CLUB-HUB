import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background message handler for Firebase Cloud Messaging.
/// 
/// This must be a top-level function annotated with `@pragma('vm:entry-point')` 
/// to ensure it is not stripped away by the Dart compiler when building for release.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

/// Service responsible for managing Firebase Cloud Messaging (FCM) push notifications
/// and local notifications display.
///
/// Handles permissions, foreground/background message routing, and FCM token
/// persistence to the Supabase backend.
class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initializes the push notification service.
  /// 
  /// This configures notification permissions, sets up background and foreground 
  /// listeners, initializes the local notifications channel (for Android), 
  /// and synchronizes the device's FCM token with the backend.
  Future<void> init() async {
    // 1. Request permissions for iOS and Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup local notifications for foreground display
    if (!kIsWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
          
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(initializationSettings);

      // Create Android channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 4. Handle messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null && !kIsWeb) {
        debugPrint('Message also contained a notification: ${message.notification}');
        
        _localNotifications.show(
          message.notification.hashCode,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 5. Get FCM Token and save to Supabase
    String? token;
    if (kIsWeb) {
      // NOTE: For web, you need to pass your VAPID key here
      token = await _fcm.getToken(vapidKey: "YOUR_VAPID_KEY_HERE");
    } else {
      token = await _fcm.getToken();
    }
    
    if (token != null) {
      await _saveTokenToSupabase(token);
    }

    // Listen to token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  /// Saves the Firebase Cloud Messaging (FCM) device token to the user's profile
  /// in the Supabase database.
  /// 
  /// This token is required to send targeted push notifications to this specific device.
  Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('FCM Token saved successfully');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }
}
