import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// NOTE: Add these Firebase packages to pubspec.yaml:
// firebase_core: ^2.24.0
// firebase_messaging: ^14.7.6
// flutter_local_notifications: ^16.3.0
//
// Uncomment imports below after adding packages:
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

/// Notification Service - Handles push notifications using Firebase Cloud Messaging
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Uncomment after adding firebase_messaging package
  // FirebaseMessaging? _messaging;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // TODO: Uncomment after adding Firebase packages
      // await _initializeFirebaseMessaging();

      _isInitialized = true;
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Initialize Firebase Cloud Messaging
  /// TODO: Uncomment after adding firebase_messaging package
  /*
  Future<void> _initializeFirebaseMessaging() async {
    // Initialize Firebase if not already initialized
    await Firebase.initializeApp();

    _messaging = FirebaseMessaging.instance;

    // Request permissions (iOS)
    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permissions granted');
    } else {
      print('⚠️ Notification permissions denied');
      return;
    }

    // Get FCM token
    _fcmToken = await _messaging!.getToken();
    print('📱 FCM Token: $_fcmToken');

    // Listen for token refresh
    _messaging!.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('🔄 FCM Token refreshed: $newToken');
      // TODO: Send updated token to backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }
  }
  */

  /// Handle foreground messages
  /// TODO: Uncomment after adding firebase_messaging package
  /*
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'PrevailMart',
        body: notification.body ?? '',
        payload: data['orderId'],
      );
    }
  }
  */

  /// Handle background message tap
  /// TODO: Uncomment after adding firebase_messaging package
  /*
  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('📱 Background message tapped: ${message.messageId}');

    final data = message.data;
    if (data['orderId'] != null) {
      // Navigate to order tracking
      // TODO: Implement navigation using NavigatorKey
    }
  }
  */

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload != null) {
      // Navigate to appropriate screen based on payload
      // TODO: Implement navigation using NavigatorKey
    }
  }

  /// Show order status notification
  Future<void> notifyOrderStatusChange({
    required String orderId,
    required String orderNumber,
    required String status,
    required String message,
  }) async {
    final statusEmojis = {
      'pending': '⏳',
      'processing': '⚙️',
      'confirmed': '✅',
      'preparing': '📦',
      'shipped': '🚚',
      'out-for-delivery': '🚀',
      'delivered': '✨',
      'cancelled': '❌',
    };

    final emoji = statusEmojis[status.toLowerCase()] ?? '📬';

    await _showLocalNotification(
      title: '$emoji Order #$orderNumber',
      body: message,
      payload: orderId,
    );
  }

  /// Show driver assigned notification
  Future<void> notifyDriverAssigned({
    required String orderId,
    required String orderNumber,
    required String driverName,
  }) async {
    await _showLocalNotification(
      title: '🚗 Driver Assigned',
      body: '$driverName is delivering your order #$orderNumber',
      payload: orderId,
    );
  }

  /// Show delivery arriving notification
  Future<void> notifyDeliveryArriving({
    required String orderId,
    required String orderNumber,
    required int minutes,
  }) async {
    await _showLocalNotification(
      title: '⏰ Delivery Arriving Soon',
      body: 'Your order #$orderNumber will arrive in approximately $minutes minutes',
      payload: orderId,
    );
  }

  /// Show order delivered notification
  Future<void> notifyOrderDelivered({
    required String orderId,
    required String orderNumber,
  }) async {
    await _showLocalNotification(
      title: '✅ Order Delivered',
      body: 'Your order #$orderNumber has been delivered successfully!',
      payload: orderId,
    );
  }

  /// Show promotional notification
  Future<void> notifyPromotion({
    required String title,
    required String message,
  }) async {
    await _showLocalNotification(
      title: '🎉 $title',
      body: message,
      payload: null,
    );
  }

  /// Request permission (mainly for iOS)
  Future<bool> requestPermission() async {
    // TODO: Uncomment after adding firebase_messaging package
    /*
    if (_messaging == null) {
      await initialize();
    }

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
    */

    // Placeholder for now
    return true;
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    // TODO: Uncomment after adding firebase_messaging package
    /*
    await _messaging?.subscribeToTopic(topic);
    print('📢 Subscribed to topic: $topic');
    */
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    // TODO: Uncomment after adding firebase_messaging package
    /*
    await _messaging?.unsubscribeFromTopic(topic);
    print('🔕 Unsubscribed from topic: $topic');
    */
  }
}

/// Singleton instance
final notificationService = NotificationService();

/// Background message handler
/// Must be a top-level function
/// TODO: Uncomment after adding firebase_messaging package
/*
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background message: ${message.messageId}');

  // Handle the message
  // Note: Can't show UI here, but can update local storage, etc.
}
*/
