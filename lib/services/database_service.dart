import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const _boxName = 'tasks';
  late Box<dynamic> _box;

  // In-memory index for faster lookups: dateKey -> list of task IDs
  final Map<String, Set<String>> _dateIndex = {};
  bool _indexBuilt = false;

  /// Call once before using any other method.
  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    _buildIndex();
  }

  void _buildIndex() {
    _dateIndex.clear();
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      final map = Map<String, dynamic>.from(raw as Map);
      final dateStr = map['date'] as String?;
      if (dateStr == null) continue;
      
      DateTime? dt;
      try {
        dt = DateTime.parse(dateStr);
      } catch (e) {
        debugPrint('Failed to parse date for task $key: $dateStr - $e');
        continue;
      }
      
      final keyDate = _dateKey(dt);
      _dateIndex.putIfAbsent(keyDate, () => {}).add(key as String);
    }
    _indexBuilt = true;
  }

  void _addToIndex(String taskId, DateTime date) {
    final key = _dateKey(date);
    _dateIndex.putIfAbsent(key, () => {}).add(taskId);
  }

  void _removeFromIndex(String taskId, DateTime date) {
    final key = _dateKey(date);
    _dateIndex[key]?.remove(taskId);
    if (_dateIndex[key]?.isEmpty ?? false) {
      _dateIndex.remove(key);
    }
  }

  void _updateIndex(String taskId, DateTime oldDate, DateTime newDate) {
    if (!_isSameDay(oldDate, newDate)) {
      _removeFromIndex(taskId, oldDate);
      _addToIndex(taskId, newDate);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── INSERT ──────────────────────────────────────────────────────────────────

  Future<void> insertTask(Task task) async {
    await _box.put(task.id, task.toJson());
    _addToIndex(task.id, task.date);
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    final existingRaw = _box.get(task.id);
    DateTime? oldDate;
    if (existingRaw != null) {
      final existingMap = Map<String, dynamic>.from(existingRaw);
      final existingDateStr = existingMap['date'] as String?;
      if (existingDateStr != null) {
        try {
          oldDate = DateTime.parse(existingDateStr);
        } catch (e) {
          debugPrint('Failed to parse existing date for task ${task.id}: $existingDateStr - $e');
        }
      }
    }

    await _box.put(task.id, task.toJson());
    if (oldDate != null) {
      _updateIndex(task.id, oldDate, task.date);
    }
  }

  // ── DELETE ──────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String id) async {
    final existingRaw = _box.get(id);
    DateTime? taskDate;
    if (existingRaw != null) {
      final existingMap = Map<String, dynamic>.from(existingRaw);
      final existingDateStr = existingMap['date'] as String?;
      if (existingDateStr != null) {
        try {
          taskDate = DateTime.parse(existingDateStr);
        } catch (e) {
          debugPrint('Failed to parse date for deleted task $id: $existingDateStr - $e');
        }
      }
    }

    await _box.delete(id);
    if (taskDate != null) {
      _removeFromIndex(id, taskDate);
    }
  }

  // ── QUERIES ─────────────────────────────────────────────────────────────────

  /// All tasks for a given day, optionally filtered by category.
  Future<List<Task>> getTasksForDay(
    DateTime day, {
    TaskCategory? category,
  }) async {
    final dayKey = _dateKey(day);

    // Use index if available for O(1) lookup instead of O(n) scan
    final taskIds = _indexBuilt ? _dateIndex[dayKey] : null;

    Iterable<Task> tasks;
    if (taskIds != null && taskIds.isNotEmpty) {
      // Fetch only tasks for this day using the index
      tasks = taskIds
          .where((id) => _box.containsKey(id))
          .map((id) {
            final raw = _box.get(id);
            if (raw == null) return null;
            try {
              return Task.fromJson(Map<String, dynamic>.from(raw));
            } catch (e) {
              debugPrint('Failed to parse task $id: $e');
              return null;
            }
          })
          .where((t) => t != null)
          .cast<Task>();
    } else {
      // Fallback to full scan if index not built or no tasks for day
      final dayTasks = <Task>[];
      for (final key in _box.keys) {
        final raw = _box.get(key);
        if (raw == null) continue;
        try {
          final t = Task.fromJson(Map<String, dynamic>.from(raw as Map));
          if (_dateKey(t.date) == dayKey) {
            dayTasks.add(t);
          }
        } catch (e) {
          debugPrint('Failed to parse task in fallback scan: $e');
        }
      }
      tasks = dayTasks;
    }

    // Apply category filter
    if (category != null) {
      tasks = tasks.where((t) => t.category == category);
    }

    final sortedTasks = tasks.toList();

    // Sort by start time (nulls last)
    sortedTasks.sort((a, b) {
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });

    return sortedTasks;
  }

  /// Returns a map of date → task count for calendar dot indicators.
  Future<Map<DateTime, int>> getTaskCountsByMonth(
    int year,
    int month,
  ) async {
    final counts = <DateTime, int>{};

    // Use index to avoid scanning all tasks
    if (_indexBuilt) {
      for (final entry in _dateIndex.entries) {
        final key = entry.key;
        // Parse year/month from key format YYYY-MM-DD
        final parts = key.split('-');
        if (parts.length == 3) {
          final taskYear = int.tryParse(parts[0]);
          final taskMonth = int.tryParse(parts[1]);
          final taskDay = int.tryParse(parts[2]);
          if (taskYear == year && taskMonth == month && taskDay != null) {
            counts[DateTime(year, month, taskDay)] = entry.value.length;
          }
        }
      }
    } else {
      // Fallback to full scan
      for (final key in _box.keys) {
        final raw = _box.get(key);
        if (raw == null) continue;
        final map = Map<String, dynamic>.from(raw as Map);
        final dateStr = map['date'] as String?;
        if (dateStr == null) continue;
        try {
          final dt = DateTime.parse(dateStr);
          if (dt.year == year && dt.month == month) {
            final keyDate = DateTime(dt.year, dt.month, dt.day);
            counts[keyDate] = (counts[keyDate] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint('Failed to parse date in getTaskCountsByMonth: $dateStr - $e');
        }
      }
    }

    return counts;
  }

  /// All tasks — used for notification rescheduling on boot.
  Future<List<Task>> getAllTasks() async {
    final tasks = <Task>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final task = Task.fromJson(Map<String, dynamic>.from(raw as Map));
        tasks.add(task);
      } catch (e) {
        debugPrint('Failed to parse task in getAllTasks: $e');
      }
    }
    return tasks;
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  String _dateKey(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
