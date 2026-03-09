import 'package:flutter_test/flutter_test.dart';
import 'package:task_organizer/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('Task toJson/fromJson should be consistent', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        date: DateTime(2026, 1, 1),
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        category: TaskCategory.work,
      );

      final json = task.toJson();
      final fromJson = Task.fromJson(json);

      expect(fromJson.id, task.id);
      expect(fromJson.title, task.title);
      expect(fromJson.description, task.description);
      expect(fromJson.date, task.date);
      expect(fromJson.priority, task.priority);
      expect(fromJson.status, task.status);
      expect(fromJson.category, task.category);
    });

    test('Task copyWith should update fields correctly', () {
      final task = Task(
        id: '1',
        title: 'Original Title',
        date: DateTime(2026, 1, 1),
      );

      final updated = task.copyWith(title: 'Updated Title', status: TaskStatus.completed);

      expect(updated.id, task.id);
      expect(updated.title, 'Updated Title');
      expect(updated.status, TaskStatus.completed);
      expect(updated.date, task.date);
    });
  });
}
