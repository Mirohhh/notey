import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/notey_launch');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleTaskNotifications(Task task) async {
    await cancelTaskNotifications(task.id);

    if (task.startTime != null && task.notifyOnStart) {
      final startId = task.id.hashCode & 0x7FFFFFFF;
      if (task.startTime!.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: startId,
          title: '🚀 Task Started',
          body: task.title,
          scheduledDate: task.startTime!,
        );
      }
    }

    if (task.deadline != null && task.notifyBeforeDeadline) {
      final deadlineId = (task.id.hashCode + 1) & 0x7FFFFFFF;
      final notifyTime =
          task.deadline!.subtract(Duration(minutes: task.notifyMinutesBefore));
      if (notifyTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: deadlineId,
          title: '⏰ Deadline Approaching',
          body: '${task.title} — due in ${task.notifyMinutesBefore} minutes',
          scheduledDate: notifyTime,
        );
      }

      final deadlineExactId = (task.id.hashCode + 2) & 0x7FFFFFFF;
      if (task.deadline!.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: deadlineExactId,
          title: '🔴 Deadline Reached',
          body: '${task.title} deadline is now!',
          scheduledDate: task.deadline!,
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Notifications for task reminders and deadlines',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: DefaultStyleInformation(true, true),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    await _notifications.cancel(taskId.hashCode & 0x7FFFFFFF);
    await _notifications.cancel((taskId.hashCode + 1) & 0x7FFFFFFF);
    await _notifications.cancel((taskId.hashCode + 2) & 0x7FFFFFFF);
  }
}
