import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_ota/main.dart';
import 'package:todo_ota/models/task.dart';
import 'package:todo_ota/services/remote_config.dart';
import 'package:todo_ota/services/task_store.dart';
import 'package:todo_ota/services/update_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Task JSON round-trip', () {
    final t = Task(
      id: '1',
      title: 'اشتري حليب',
      note: 'لبن كامل الدسم',
      priority: Priority.high,
      createdAt: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 3),
    );
    final back = Task.decodeList(Task.encodeList([t])).single;
    expect(back.title, t.title);
    expect(back.priority, Priority.high);
    expect(back.dueDate, t.dueDate);
  });

  test('RemoteConfig parses JSON with defaults', () {
    final c = RemoteConfig.fromJson({
      'app_title': 'X',
      'primary_color': '#FF0000',
      'announcement': {'enabled': true, 'text': 'hi'},
      'apk_update': {'min_build': 5},
    });
    expect(c.appTitle, 'X');
    expect(c.primaryColor, const Color(0xFFFF0000));
    expect(c.announcementEnabled, true);
    expect(c.minBuild, 5);
    expect(c.showStats, true);
  });

  test('TaskStore persists, filters and sorts', () async {
    final s = TaskStore();
    await s.load();
    await s.add(Task(id: 'a', title: 'A', createdAt: DateTime(2026, 1, 1)));
    await s.add(Task(
        id: 'b', title: 'B', priority: Priority.high, createdAt: DateTime(2026, 1, 2)));
    await s.toggle(s.all.firstWhere((t) => t.id == 'a'));

    expect(s.visible.map((t) => t.id), ['b', 'a']); // undone & high first
    s.setFilter(TaskFilter.done);
    expect(s.visible.single.id, 'a');

    final s2 = TaskStore();
    await s2.load();
    expect(s2.all.length, 2);
    await s2.clearDone();
    expect(s2.all.single.id, 'b');
  });

  testWidgets('add a task through the UI', (tester) async {
    final store = TaskStore();
    await store.load();
    final app = TodoApp(
      store: store,
      remote: RemoteConfigService(),
      updates: UpdateService(),
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('لا توجد مهام بعد — أضف أول مهمة!'), findsOneWidget);

    await tester.tap(find.text('مهمة جديدة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'مهمة تجريبية');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('مهمة تجريبية'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(store.doneCount, 1);
  });
}
