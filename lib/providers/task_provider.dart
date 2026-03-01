import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  final _uuid = const Uuid();

  // In-memory cache for the currently selected day
  List<Task> _dayTasks = [];
  List<Task> get dayTasks => _dayTasks;

  // Calendar dot counts — loaded per month
  Map<DateTime, int> _monthCounts = {};
  Map<DateTime, int> get monthCounts => _monthCounts;

  TaskCategory? _activeFilter;
  TaskCategory? get activeFilter => _activeFilter;

  DateTime? _loadedDay;

  // ── FILTER ──────────────────────────────────────────────────────────────────

  Future<void> setFilter(TaskCategory? category) async {
    _activeFilter = category;
    notifyListeners();
    if (_loadedDay != null) await loadDay(_loadedDay!);
  }

  // ── LOAD ────────────────────────────────────────────────────────────────────

  /// Call when the user taps a day on the calendar.
  Future<void> loadDay(DateTime day) async {
    _loadedDay = day;
    _dayTasks = await _db.getTasksForDay(day, category: _activeFilter);
    notifyListeners();
  }

  /// Call when the calendar page changes months.
  Future<void> loadMonthCounts(int year, int month) async {
    _monthCounts = await _db.getTaskCountsByMonth(year, month);
    notifyListeners();
  }

  // ── CREATE ──────────────────────────────────────────────────────────────────

  Future<void> addTask({
    required String title,
    String description = '',
    required DateTime date,
    DateTime? startTime,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.other,
    bool notifyOnStart = true,
    bool notifyBeforeDeadline = true,
    int notifyMinutesBefore = 30,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      date: date,
      startTime: startTime,
      deadline: deadline,
      priority: priority,
      category: category,
      notifyOnStart: notifyOnStart,
      notifyBeforeDeadline: notifyBeforeDeadline,
      notifyMinutesBefore: notifyMinutesBefore,
    );

    await _db.insertTask(task);
    await _notifications.scheduleTaskNotifications(task);
    await _refreshAfterChange(date);
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    await _notifications.scheduleTaskNotifications(task);
    await _refreshAfterChange(task.date);
  }

  Future<void> toggleTaskStatus(String id) async {
    final task = _dayTasks.firstWhere((t) => t.id == id);
    final updated = task.copyWith(
      status: task.status == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed,
    );
    await _db.updateTask(updated);
    // Update in-memory list directly for instant UI response
    final idx = _dayTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _dayTasks[idx] = updated;
      notifyListeners();
    }
  }

  // ── DELETE ──────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String id) async {
    final task = _dayTasks.firstWhere((t) => t.id == id);
    await _notifications.cancelTaskNotifications(id);
    await _db.deleteTask(id);
    await _refreshAfterChange(task.date);
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  Future<void> _refreshAfterChange(DateTime date) async {
    // Refresh the day list if we're still on the same day
    if (_loadedDay != null) await loadDay(_loadedDay!);
    // Refresh month counts so calendar dots stay accurate
    await loadMonthCounts(date.year, date.month);
  }
}
