import 'dart:convert';

enum Priority { low, normal, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.low => 'منخفضة',
        Priority.normal => 'عادية',
        Priority.high => 'عالية',
      };
}

class Task {
  final String id;
  final String title;
  final String note;
  final bool done;
  final Priority priority;
  final DateTime createdAt;
  final DateTime? dueDate;

  const Task({
    required this.id,
    required this.title,
    this.note = '',
    this.done = false,
    this.priority = Priority.normal,
    required this.createdAt,
    this.dueDate,
  });

  Task copyWith({
    String? title,
    String? note,
    bool? done,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        note: note ?? this.note,
        done: done ?? this.done,
        priority: priority ?? this.priority,
        createdAt: createdAt,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'done': done,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        note: j['note'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        priority: Priority.values.firstWhere(
          (p) => p.name == j['priority'],
          orElse: () => Priority.normal,
        ),
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        dueDate: j['dueDate'] == null
            ? null
            : DateTime.tryParse(j['dueDate'] as String),
      );

  static String encodeList(List<Task> tasks) =>
      jsonEncode(tasks.map((t) => t.toJson()).toList());

  static List<Task> decodeList(String raw) {
    final data = jsonDecode(raw);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Task.fromJson)
        .toList();
  }
}
