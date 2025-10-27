import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification_model.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

/// Notification Service - Handles all notification operations
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();

  final List<NotificationModel> _notificationHistory = [];

  /// Stream of incoming notifications
  Stream<NotificationModel> get notificationStream =>
      _notificationStreamController.stream;

  /// Get notification history
  List<NotificationModel> get notificationHistory => _notificationHistory;

  /// Get unread count
  int get unreadCount =>
      _notificationHistory.where((n) => !n.isRead).length;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request permissions
      await requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure FCM
      await _configureFCM();

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // Request FCM permission
      final fcmStatus = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (fcmStatus.authorizationStatus != AuthorizationStatus.authorized) {
        print('⚠️ FCM permission not granted');
        return false;
      }

      // Request notification permission (iOS)
      if (Platform.isIOS) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          print('⚠️ iOS notification permission not granted');
          return false;
        }
      }

      print('✅ Notification permissions granted');
      return true;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final channels = [
      const AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Notifications about your order status',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        'delivery_updates',
        'Delivery Updates',
        description: 'Real-time delivery tracking notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
      const AndroidNotificationChannel(
        'promotional',
        'Promotions',
        description: 'Special offers and deals',
        importance: Importance.low,
        playSound: false,
      ),
    ];

    for (var channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureFCM() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    final token = await _fcm.getToken();
    print('📱 FCM Token: $token');

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      print('📱 FCM Token refreshed: $newToken');
      // TODO: Send token to backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Handle notification taps (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from notification');
      _handleNotificationTap(message.data.toString());
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App opened from terminated state via notification');
      _handleNotificationTap(initialMessage.data.toString());
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = _createNotificationFromFCM(message);

    // Add to history
    _notificationHistory.insert(0, notification);

    // Emit to stream
    _notificationStreamController.add(notification);

    // Show local notification
    _showLocalNotification(notification);
  }

  /// Create notification model from FCM message
  NotificationModel _createNotificationFromFCM(RemoteMessage message) {
    final data = message.data;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? data['title'] ?? 'New Notification',
      body: message.notification?.body ?? data['body'] ?? '',
      type: NotificationModel.parseNotificationType(data['type']),
      priority: NotificationModel.parsePriority(data['priority']),
      timestamp: DateTime.now(),
      data: data,
      orderId: data['orderId'],
      trackingNumber: data['trackingNumber'],
      imageUrl: message.notification?.android?.imageUrl ?? data['imageUrl'],
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    final channelId = _getChannelIdForType(notification.type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelNameForType(notification.type),
      channelDescription: 'Notification channel for ${notification.type}',
      importance: notification.priority == NotificationPriority.urgent
          ? Importance.max
          : notification.priority == NotificationPriority.high
              ? Importance.high
              : Importance.defaultImportance,
      priority: notification.priority == NotificationPriority.urgent
          ? Priority.max
          : notification.priority == NotificationPriority.high
              ? Priority.high
              : Priority.defaultPriority,
      playSound: notification.shouldPlaySound,
      enableVibration: notification.shouldVibrate,
      icon: '@mipmap/ic_launcher',
      largeIcon: notification.imageUrl != null
          ? DrawableResourceAndroidBitmap('@mipmap/ic_launcher')
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: notification.shouldPlaySound,
      sound: notification.shouldPlaySound ? 'default' : null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: notification.toJson().toString(),
    );
  }

  /// Get channel ID for notification type
  String _getChannelIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.orderConfirmed:
      case NotificationType.orderStatusUpdate:
      case NotificationType.orderCancelled:
        return 'order_updates';
      case NotificationType.driverAssigned:
      case NotificationType.orderPickedUp:
      case NotificationType.driverNearby:
      case NotificationType.orderDelivered:
        return 'delivery_updates';
      case NotificationType.promotional:
        return 'promotional';
      default:
        return 'order_updates';
    }
  }

  /// Get channel name for notification type
  String _getChannelNameForType(NotificationType type) {
    switch (type) {
      case NotificationType.orderConfirmed:
      case NotificationType.orderStatusUpdate:
      case NotificationType.orderCancelled:
        return 'Order Updates';
      case NotificationType.driverAssigned:
      case NotificationType.orderPickedUp:
      case NotificationType.driverNearby:
      case NotificationType.orderDelivered:
        return 'Delivery Updates';
      case NotificationType.promotional:
        return 'Promotions';
      default:
        return 'General';
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      // TODO: Navigate to appropriate screen based on payload
      print('Notification tapped: $payload');
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  /// Show order status notification
  Future<void> showOrderNotification({
    required String orderId,
    required String trackingNumber,
    required String status,
    String? driverName,
    String? estimatedTime,
  }) async {
    NotificationType type;
    String title;
    String body;
    NotificationPriority priority;

    switch (status.toLowerCase()) {
      case 'confirmed':
        type = NotificationType.orderConfirmed;
        title = 'Order Confirmed!';
        body = 'Your order #$trackingNumber has been confirmed and is being prepared.';
        priority = NotificationPriority.medium;
        break;
      case 'assigned':
        type = NotificationType.driverAssigned;
        title = 'Driver Assigned!';
        body = driverName != null
            ? '$driverName is assigned to deliver your order.'
            : 'A driver has been assigned to your order.';
        priority = NotificationPriority.high;
        break;
      case 'picked_up':
        type = NotificationType.orderPickedUp;
        title = 'Order Picked Up!';
        body = estimatedTime != null
            ? 'Your order is on the way! Estimated arrival: $estimatedTime'
            : 'Your order is on the way!';
        priority = NotificationPriority.high;
        break;
      case 'delivered':
        type = NotificationType.orderDelivered;
        title = 'Order Delivered!';
        body = 'Your order has been successfully delivered. Enjoy!';
        priority = NotificationPriority.high;
        break;
      case 'cancelled':
        type = NotificationType.orderCancelled;
        title = 'Order Cancelled';
        body = 'Your order #$trackingNumber has been cancelled.';
        priority = NotificationPriority.medium;
        break;
      default:
        type = NotificationType.orderStatusUpdate;
        title = 'Order Update';
        body = 'Your order status has been updated to: $status';
        priority = NotificationPriority.low;
    }

    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      priority: priority,
      timestamp: DateTime.now(),
      orderId: orderId,
      trackingNumber: trackingNumber,
    );

    // Add to history
    _notificationHistory.insert(0, notification);

    // Emit to stream
    _notificationStreamController.add(notification);

    // Show notification
    await _showLocalNotification(notification);
  }

  /// Show driver nearby notification
  Future<void> showDriverNearbyNotification({
    required String orderId,
    required String trackingNumber,
    required String driverName,
    String? estimatedMinutes,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Driver Nearby!',
      body: estimatedMinutes != null
          ? '$driverName is $estimatedMinutes away from your location.'
          : '$driverName is approaching your delivery location.',
      type: NotificationType.driverNearby,
      priority: NotificationPriority.urgent,
      timestamp: DateTime.now(),
      orderId: orderId,
      trackingNumber: trackingNumber,
    );

    _notificationHistory.insert(0, notification);
    _notificationStreamController.add(notification);
    await _showLocalNotification(notification);
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notificationHistory.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notificationHistory[index] = _notificationHistory[index].copyWith(isRead: true);
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (var i = 0; i < _notificationHistory.length; i++) {
      _notificationHistory[i] = _notificationHistory[i].copyWith(isRead: true);
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notificationHistory.clear();
    _localNotifications.cancelAll();
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  /// Dispose
  void dispose() {
    _notificationStreamController.close();
  }
}

/// Singleton instance
final notificationService = NotificationService();
