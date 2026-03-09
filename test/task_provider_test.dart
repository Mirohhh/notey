import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_organizer/models/task.dart';
import 'package:task_organizer/providers/task_provider.dart';
import 'package:task_organizer/services/database_service.dart';
import 'package:task_organizer/services/notification_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockNotificationService extends Mock implements NotificationService {}

class FakeTask extends Fake implements Task {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock home_widget MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (MethodCall methodCall) async {
        return null;
      },
    );

    registerFallbackValue(DateTime(2026));
    registerFallbackValue(TaskCategory.other);
    registerFallbackValue(FakeTask());
  });

  late TaskProvider provider;
  late MockDatabaseService mockDb;
  late MockNotificationService mockNotifications;

  setUp(() {
    mockDb = MockDatabaseService();
    mockNotifications = MockNotificationService();
    provider = TaskProvider(db: mockDb, notifications: mockNotifications);

    // Default setups
    when(() => mockDb.getTasksForDay(any(), category: any(named: 'category')))
        .thenAnswer((_) async => []);
    when(() => mockDb.getTaskCountsByMonth(any(), any()))
        .thenAnswer((_) async => {});
  });

  group('TaskProvider Tests', () {
    final testTask = Task(
      id: 'abc',
      title: 'Test Task',
      date: DateTime.now(),
    );

    test('deleteTask should remove task locally and call DB', () async {
      // Setup: add task to local state via loadDay (mocked)
      when(() => mockDb.getTasksForDay(any(), category: any(named: 'category')))
          .thenAnswer((_) async => [testTask]);
      
      await provider.loadDay(testTask.date);
      expect(provider.dayTasks.length, 1);

      when(() => mockDb.deleteTask(any())).thenAnswer((_) async => {});
      when(() => mockNotifications.cancelTaskNotifications(any())).thenAnswer((_) async => {});

      await provider.deleteTask(testTask.id);

      expect(provider.dayTasks.isEmpty, true);
      verify(() => mockDb.deleteTask(testTask.id)).called(1);
    });

    test('deleteTask should rollback on DB failure', () async {
      when(() => mockDb.getTasksForDay(any(), category: any(named: 'category')))
          .thenAnswer((_) async => [testTask]);
      
      await provider.loadDay(testTask.date);
      expect(provider.dayTasks.length, 1);

      // Simulate DB failure
      when(() => mockDb.deleteTask(any())).thenThrow(Exception('DB Error'));
      when(() => mockNotifications.cancelTaskNotifications(any())).thenAnswer((_) async => {});

      // Use runZoned to suppress the expected "Failed to delete task" debugPrint
      await runZoned(() async {
        try {
          await provider.deleteTask(testTask.id);
        } catch (_) {
          // Expected
        }
      }, zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          if (!line.contains('Failed to delete task: Exception: DB Error')) {
            parent.print(zone, line);
          }
        },
      ));

      // Check rollback: task should be back in the list
      expect(provider.dayTasks.length, 1);
      expect(provider.dayTasks.first.id, testTask.id);
    });

    test('undoDelete should re-insert task', () async {
      when(() => mockDb.insertTask(any())).thenAnswer((_) async => {});
      when(() => mockNotifications.scheduleTaskNotifications(any())).thenAnswer((_) async => {});
      when(() => mockDb.getTasksForDay(any(), category: any(named: 'category')))
          .thenAnswer((_) async => [testTask]);

      await provider.loadDay(testTask.date); // Sets _loadedDay

      await provider.undoDelete(testTask);

      verify(() => mockDb.insertTask(testTask)).called(1);
      verify(() => mockNotifications.scheduleTaskNotifications(testTask)).called(1);
    });
  });
}
