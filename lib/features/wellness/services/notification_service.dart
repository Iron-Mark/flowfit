import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
      try {
        await _plugin.initialize(settings);
      } catch (e) {
        // ignore missing plugin in tests or unsupported platforms
      }
    // Request iOS permissions
      try {
        await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
      } catch (_) {}
    _isInitialized = true;
  }

  static Future<void> showNotification({required String title, required String body, int id = 0}) async {
    if (!_isInitialized) await init();
    const androidChannel = AndroidNotificationDetails('geofence', 'Geofence', importance: Importance.max, priority: Priority.high);
    const iosChannel = DarwinNotificationDetails();
    final platform = NotificationDetails(android: androidChannel, iOS: iosChannel);
    try {
      await _plugin.show(id, title, body, platform);
    } catch (e) {
      // In tests or unsupported platforms, plugin might not be available; swallow errors
    }
  }
}
