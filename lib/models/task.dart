import 'dart:convert';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

enum TaskCategory {
  personal,
  work,
  health,
  shopping,
  finance,
  learning,
  other;

  String get label => switch (this) {
        TaskCategory.personal => 'Personal',
        TaskCategory.work => 'Work',
        TaskCategory.health => 'Health',
        TaskCategory.shopping => 'Shopping',
        TaskCategory.finance => 'Finance',
        TaskCategory.learning => 'Learning',
        TaskCategory.other => 'Other',
      };

  String get emoji => switch (this) {
        TaskCategory.personal => '🏠',
        TaskCategory.work => '💼',
        TaskCategory.health => '❤️',
        TaskCategory.shopping => '🛒',
        TaskCategory.finance => '💰',
        TaskCategory.learning => '📚',
        TaskCategory.other => '📌',
      };
}

class Task {
  final String id;
  String title;
  String description;
  DateTime date;
  DateTime? startTime;
  DateTime? deadline;
  TaskPriority priority;
  TaskStatus status;
  TaskCategory category;
  bool notifyOnStart;
  bool notifyBeforeDeadline;
  int notifyMinutesBefore;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.startTime,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.category = TaskCategory.other,
    this.notifyOnStart = true,
    this.notifyBeforeDeadline = true,
    this.notifyMinutesBefore = 30,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? deadline,
    TaskPriority? priority,
    TaskStatus? status,
    TaskCategory? category,
    bool? notifyOnStart,
    bool? notifyBeforeDeadline,
    int? notifyMinutesBefore,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      notifyOnStart: notifyOnStart ?? this.notifyOnStart,
      notifyBeforeDeadline: notifyBeforeDeadline ?? this.notifyBeforeDeadline,
      notifyMinutesBefore: notifyMinutesBefore ?? this.notifyMinutesBefore,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'startTime': startTime?.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'priority': priority.index,
        'status': status.index,
        'category': category.index,
        'notifyOnStart': notifyOnStart,
        'notifyBeforeDeadline': notifyBeforeDeadline,
        'notifyMinutesBefore': notifyMinutesBefore,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        date: DateTime.parse(json['date']),
        startTime:
            json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
        deadline:
            json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
        priority: TaskPriority.values[json['priority'] ?? 1],
        status: TaskStatus.values[json['status'] ?? 0],
        category: TaskCategory.values[json['category'] ?? 6],
        notifyOnStart: json['notifyOnStart'] ?? true,
        notifyBeforeDeadline: json['notifyBeforeDeadline'] ?? true,
        notifyMinutesBefore: json['notifyMinutesBefore'] ?? 30,
      );

  String toJsonString() => jsonEncode(toJson());
  factory Task.fromJsonString(String str) => Task.fromJson(jsonDecode(str));
}
