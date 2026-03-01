import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'focus_tasks.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id                      TEXT PRIMARY KEY,
        title                   TEXT NOT NULL,
        description             TEXT DEFAULT '',
        date                    TEXT NOT NULL,
        start_time              TEXT,
        deadline                TEXT,
        priority                INTEGER DEFAULT 1,
        status                  INTEGER DEFAULT 0,
        category                INTEGER DEFAULT 6,
        notify_on_start         INTEGER DEFAULT 1,
        notify_before_deadline  INTEGER DEFAULT 1,
        notify_minutes_before   INTEGER DEFAULT 30
      )
    ''');

    // Index on date for fast day lookups
    await db.execute(
        'CREATE INDEX idx_tasks_date ON tasks (date)');

    // Index on category for fast filter queries
    await db.execute(
        'CREATE INDEX idx_tasks_category ON tasks (category)');
  }

  // ── INSERT ──────────────────────────────────────────────────────────────────

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      _toMap(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      _toMap(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // ── DELETE ──────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ── QUERIES ─────────────────────────────────────────────────────────────────

  /// All tasks for a given day, optionally filtered by category.
  Future<List<Task>> getTasksForDay(
    DateTime day, {
    TaskCategory? category,
  }) async {
    final db = await database;
    final dayKey = _dateKey(day);

    final where = category != null
        ? 'date = ? AND category = ?'
        : 'date = ?';
    final args = category != null
        ? [dayKey, category.index]
        : [dayKey];

    final rows = await db.query(
      'tasks',
      where: where,
      whereArgs: args,
      orderBy: 'start_time ASC',
    );

    return rows.map(_fromMap).toList();
  }

  /// Returns a map of date → task count for calendar dot indicators.
  /// Much cheaper than loading every task.
  Future<Map<DateTime, int>> getTaskCountsByMonth(
    int year,
    int month,
  ) async {
    final db = await database;
    // e.g. "2025-03-%"
    final pattern =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-%';

    final rows = await db.rawQuery(
      'SELECT date, COUNT(*) as cnt FROM tasks WHERE date LIKE ? GROUP BY date',
      [pattern],
    );

    final map = <DateTime, int>{};
    for (final row in rows) {
      final parts = (row['date'] as String).split('-');
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      map[dt] = (row['cnt'] as int);
    }
    return map;
  }

  /// All tasks — used for notification rescheduling on boot.
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final rows = await db.query('tasks');
    return rows.map(_fromMap).toList();
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _toMap(Task t) => {
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'date': _dateKey(t.date),
        'start_time': t.startTime?.toIso8601String(),
        'deadline': t.deadline?.toIso8601String(),
        'priority': t.priority.index,
        'status': t.status.index,
        'category': t.category.index,
        'notify_on_start': t.notifyOnStart ? 1 : 0,
        'notify_before_deadline': t.notifyBeforeDeadline ? 1 : 0,
        'notify_minutes_before': t.notifyMinutesBefore,
      };

  Task _fromMap(Map<String, dynamic> m) => Task(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String? ?? '',
        date: DateTime.parse(m['date'] as String),
        startTime: m['start_time'] != null
            ? DateTime.parse(m['start_time'] as String)
            : null,
        deadline: m['deadline'] != null
            ? DateTime.parse(m['deadline'] as String)
            : null,
        priority: TaskPriority.values[m['priority'] as int],
        status: TaskStatus.values[m['status'] as int],
        category: TaskCategory.values[m['category'] as int],
        notifyOnStart: (m['notify_on_start'] as int) == 1,
        notifyBeforeDeadline: (m['notify_before_deadline'] as int) == 1,
        notifyMinutesBefore: m['notify_minutes_before'] as int,
      );
}
