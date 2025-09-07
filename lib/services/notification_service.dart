import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permission
    await _requestPermission();

    // Initialize Android settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize iOS settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  /// Request notification permission
  Future<bool> _requestPermission() async {
    final status = await Permission.notification.request();
    print('📱 Notification permission status: $status');
    return status.isGranted;
  }

  /// Show a message notification
  Future<void> showMessageNotification({
    required String title,
    required String body,
    required String groupName,
    required int groupId,
    String? senderName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Notifications',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true, // Show even when app is in foreground
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      presentBanner: true, // Show banner even when app is in foreground
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use groupId as notification ID to avoid duplicates
    await _notifications.show(
      groupId,
      title,
      body,
      details,
      payload: 'group_$groupId', // Pass group ID as payload for navigation
    );

    print('📱 Notification shown: $title - $body');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // TODO: Navigate to the specific group chat
    // This will be handled by the main app when we integrate it
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('📱 All notifications cancelled');
  }

  /// Cancel notifications for a specific group
  Future<void> cancelGroupNotifications(int groupId) async {
    await _notifications.cancel(groupId);
    print('📱 Notifications cancelled for group: $groupId');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission if not granted
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Test notification (for debugging)
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    await showMessageNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Pally!',
      groupName: 'Test Group',
      groupId: 999,
      senderName: 'Test User',
    );
  }
}
