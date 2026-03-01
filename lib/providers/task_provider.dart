import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  final _uuid = const Uuid();

  List<Task> _dayTasks = [];
  List<Task> get dayTasks => _dayTasks;

  Map<DateTime, int> _monthCounts = {};
  Map<DateTime, int> get monthCounts => _monthCounts;

  TaskCategory? _activeFilter;
  TaskCategory? get activeFilter => _activeFilter;

  DateTime? _loadedDay;

  // IDs currently being deleted — filtered out of any loadDay result
  final Set<String> _pendingDeletes = {};

  // ── FILTER ──────────────────────────────────────────────────────────────────

  Future<void> setFilter(TaskCategory? category) async {
    _activeFilter = category;
    notifyListeners();
    if (_loadedDay != null) await loadDay(_loadedDay!);
  }

  // ── LOAD ────────────────────────────────────────────────────────────────────

  Future<void> loadDay(DateTime day) async {
    _loadedDay = day;
    final tasks = await _db.getTasksForDay(day, category: _activeFilter);
    // Strip any tasks that are mid-delete so they never reappear
    _dayTasks = tasks
        .where((t) => !_pendingDeletes.contains(t.id))
        .toList();
    notifyListeners();
  }

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

    // Optimistic — add to UI immediately if it belongs to the current day view
    final visibleNow = _loadedDay != null &&
        _isSameDay(date, _loadedDay!) &&
        (_activeFilter == null || _activeFilter == category);

    if (visibleNow) {
      _dayTasks = [..._dayTasks, task];
      _incrementCount(date);
      notifyListeners();
    }

    await _db.insertTask(task);
    await _notifications.scheduleTaskNotifications(task);

    // Re-sync to get correct DB sort order
    if (visibleNow && _loadedDay != null) await loadDay(_loadedDay!);
    await loadMonthCounts(date.year, date.month);
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    // Optimistic update in place
    final idx = _dayTasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _dayTasks = List.of(_dayTasks)..[idx] = task;
      notifyListeners();
    }

    await _db.updateTask(task);
    await _notifications.scheduleTaskNotifications(task);

    if (_loadedDay != null) await loadDay(_loadedDay!);
    await loadMonthCounts(task.date.year, task.date.month);
  }

  Future<void> toggleTaskStatus(String id) async {
    final idx = _dayTasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final task = _dayTasks[idx];
    final updated = task.copyWith(
      status: task.status == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed,
    );
    _dayTasks = List.of(_dayTasks)..[idx] = updated;
    notifyListeners();
    await _db.updateTask(updated);
  }

  // ── DELETE ──────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String id) async {
    final task = _dayTasks.firstWhere((t) => t.id == id);

    // Mark as pending-delete so loadDay never re-introduces it
    _pendingDeletes.add(id);

    // Optimistic removal
    _dayTasks = _dayTasks.where((t) => t.id != id).toList();
    _decrementCount(task.date);
    notifyListeners();

    await _notifications.cancelTaskNotifications(id);
    await _db.deleteTask(id);

    // Safe to remove from pending set now that DB confirms deletion
    _pendingDeletes.remove(id);

    await loadMonthCounts(task.date.year, task.date.month);
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _incrementCount(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    _monthCounts = Map.of(_monthCounts)
      ..[key] = (_monthCounts[key] ?? 0) + 1;
  }

  void _decrementCount(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    final current = _monthCounts[key] ?? 0;
    _monthCounts = Map.of(_monthCounts)
      ..[key] = (current - 1).clamp(0, 999);
  }
}
