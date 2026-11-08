import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/reminder_model.dart';

/// Local Push Notification service to alert students about approaching task deadlines (H-1).
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'netlearn_deadlines';
  static const String _channelName = 'Pengingat Tugas NetLearn';
  static const String _channelDesc = 'Notifikasi otomatis saat deadline tugas mendekati H-1';
  static const String _sentPrefPrefix = 'notif_sent_quiz_';

  Future<void> init() async {
    if (_initialized) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidInit,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
      );

      // Create Android Notification Channel
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );
        // Request permission on Android 13+
        await androidPlatform.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService init error: $e');
    }
  }

  /// Sends a local notification to the device tray.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (!_initialized) await init();

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  /// Synchronizes student deadline reminders: triggers a notification if any task is within H-1 (24 hours).
  Future<void> syncDeadlineReminders(List<ReminderItem> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      for (final reminder in reminders) {
        if (reminder.deadline == null) continue;

        final diff = reminder.deadline!.difference(now);
        // Only trigger if approaching deadline within 24 hours (H-1) and not expired
        if (diff.inSeconds > 0 && diff.inHours <= 24) {
          final sentKey = '$_sentPrefPrefix${reminder.id}_${now.day}_${now.month}';
          final alreadySentToday = prefs.getBool(sentKey) ?? false;

          if (!alreadySentToday) {
            final hoursLeft = diff.inHours > 0 ? '${diff.inHours} jam' : '${diff.inMinutes} menit';
            await showNotification(
              id: reminder.id.hashCode,
              title: '⏰ Pengingat Deadline Tugas: ${reminder.title}',
              body: 'Tugas "${reminder.title}" akan berakhir dalam $hoursLeft lagi. Segera kerjakan di NetLearn!',
            );

            await prefs.setBool(sentKey, true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing deadline notifications: $e');
    }
  }
}

