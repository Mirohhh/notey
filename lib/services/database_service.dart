import 'package:hive/hive.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const _boxName = 'tasks';
  late Box<Map> _box;

  /// Call once before using any other method.
  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  // ── INSERT ──────────────────────────────────────────────────────────────────

  Future<void> insertTask(Task task) async {
    await _box.put(task.id, task.toJson());
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    await _box.put(task.id, task.toJson());
  }

  // ── DELETE ──────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  // ── QUERIES ─────────────────────────────────────────────────────────────────

  /// All tasks for a given day, optionally filtered by category.
  Future<List<Task>> getTasksForDay(
    DateTime day, {
    TaskCategory? category,
  }) async {
    final dayKey = _dateKey(day);

    final tasks = _box.values
        .map((raw) => Task.fromJson(Map<String, dynamic>.from(raw)))
        .where((t) {
      if (_dateKey(t.date) != dayKey) return false;
      if (category != null && t.category != category) return false;
      return true;
    }).toList();

    // Sort by start time (nulls last)
    tasks.sort((a, b) {
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });

    return tasks;
  }

  /// Returns a map of date → task count for calendar dot indicators.
  Future<Map<DateTime, int>> getTaskCountsByMonth(
    int year,
    int month,
  ) async {
    final counts = <DateTime, int>{};

    for (final raw in _box.values) {
      final map = Map<String, dynamic>.from(raw);
      final dateStr = map['date'] as String?;
      if (dateStr == null) continue;
      final dt = DateTime.parse(dateStr);
      if (dt.year == year && dt.month == month) {
        final key = DateTime(dt.year, dt.month, dt.day);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// All tasks — used for notification rescheduling on boot.
  Future<List<Task>> getAllTasks() async {
    return _box.values
        .map((raw) => Task.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  String _dateKey(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
