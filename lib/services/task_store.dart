import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

enum TaskFilter { all, active, done }

/// يخزّن المهام محلياً على الجهاز (تبقى بعد التحديثات وإعادة التشغيل).
class TaskStore extends ChangeNotifier {
  static const _key = 'tasks_v1';

  final List<Task> _tasks = [];
  TaskFilter filter = TaskFilter.all;
  bool loaded = false;

  List<Task> get all => List.unmodifiable(_tasks);

  List<Task> get visible {
    final list = switch (filter) {
      TaskFilter.all => _tasks.toList(),
      TaskFilter.active => _tasks.where((t) => !t.done).toList(),
      TaskFilter.done => _tasks.where((t) => t.done).toList(),
    };
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final p = b.priority.index.compareTo(a.priority.index);
      if (p != 0) return p;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  int get doneCount => _tasks.where((t) => t.done).length;
  int get activeCount => _tasks.length - doneCount;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _tasks.clear();
    if (raw != null) {
      try {
        _tasks.addAll(Task.decodeList(raw));
      } catch (_) {/* بيانات تالفة — نبدأ من جديد */}
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Task.encodeList(_tasks));
  }

  void setFilter(TaskFilter f) {
    filter = f;
    notifyListeners();
  }

  Future<void> add(Task t) async {
    _tasks.add(t);
    notifyListeners();
    await _save();
  }

  Future<void> update(Task t) async {
    final i = _tasks.indexWhere((x) => x.id == t.id);
    if (i == -1) return;
    _tasks[i] = t;
    notifyListeners();
    await _save();
  }

  Future<void> toggle(Task t) => update(t.copyWith(done: !t.done));

  Future<Task?> remove(String id) async {
    final i = _tasks.indexWhere((x) => x.id == id);
    if (i == -1) return null;
    final removed = _tasks.removeAt(i);
    notifyListeners();
    await _save();
    return removed;
  }

  Future<void> clearDone() async {
    _tasks.removeWhere((t) => t.done);
    notifyListeners();
    await _save();
  }
}
