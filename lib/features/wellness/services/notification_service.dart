import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _isInitialized = true;
  }

  static Future<void> showNotification({required String title, required String body, int id = 0}) async {
    if (!_isInitialized) await init();
    const androidChannel = AndroidNotificationDetails('geofence', 'Geofence', importance: Importance.max, priority: Priority.high);
    const iosChannel = DarwinNotificationDetails();
    final platform = NotificationDetails(android: androidChannel, iOS: iosChannel);
    await _plugin.show(id, title, body, platform);
  }
}
