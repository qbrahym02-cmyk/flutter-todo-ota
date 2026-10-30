import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task.dart';
import '../services/remote_config.dart';
import '../services/task_store.dart';
import '../services/update_service.dart';
import '../widgets/task_editor.dart';
import 'updates_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.remote,
    required this.updates,
  });

  final TaskStore store;
  final RemoteConfigService remote;
  final UpdateService updates;

  Future<void> _add(BuildContext context) async {
    final t = await showTaskEditor(
      context,
      showPriority: remote.config.showPriority,
    );
    if (t != null) await store.add(t);
  }

  Future<void> _edit(BuildContext context, Task task) async {
    final t = await showTaskEditor(
      context,
      initial: task,
      showPriority: remote.config.showPriority,
    );
    if (t != null) await store.update(t);
  }

  Future<void> _delete(BuildContext context, Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    final removed = await store.remove(task.id);
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('تم حذف "${removed.title}"'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => store.add(removed),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, remote, updates]),
      builder: (context, _) {
        final cfg = remote.config;
        final tasks = store.visible;
        final needsApk =
            cfg.minBuild > 0 && updates.buildNumber > 0 && updates.buildNumber < cfg.minBuild;

        return Scaffold(
          appBar: AppBar(
            title: Text(cfg.appTitle),
            actions: [
              if (store.doneCount > 0)
                IconButton(
                  tooltip: 'حذف المكتملة',
                  icon: const Icon(Icons.cleaning_services_outlined),
                  onPressed: () => _confirmClearDone(context),
                ),
              IconButton(
                tooltip: 'التحديثات',
                icon: Badge(
                  isLabelVisible: updates.state == OtaState.readyToRestart || needsApk,
                  child: const Icon(Icons.system_update_outlined),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdatesScreen(remote: remote, updates: updates),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _add(context),
            icon: const Icon(Icons.add),
            label: const Text('مهمة جديدة'),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([remote.refresh(), updates.check()]);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (updates.state == OtaState.readyToRestart)
                  SliverToBoxAdapter(
                    child: _Banner(
                      icon: Icons.rocket_launch_outlined,
                      color: Colors.green,
                      text: 'تم تنزيل تحديث جديد ✨ أغلق التطبيق وافتحه لتفعيله.',
                      actionLabel: 'إغلاق الآن',
                      onAction: updates.closeToApply,
                    ),
                  ),
                if (needsApk)
                  SliverToBoxAdapter(
                    child: _Banner(
                      icon: Icons.download_outlined,
                      color: Colors.orange,
                      text: cfg.apkUpdateMessage,
                      actionLabel: 'تحميل',
                      onAction: () => launchUrl(Uri.parse(cfg.apkUrl),
                          mode: LaunchMode.externalApplication),
                    ),
                  ),
                if (cfg.announcementEnabled && cfg.announcementText.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _Banner(
                      icon: Icons.campaign_outlined,
                      color: cfg.primaryColor,
                      text: cfg.announcementText,
                      actionLabel: cfg.announcementUrl == null ? null : 'فتح',
                      onAction: cfg.announcementUrl == null
                          ? null
                          : () => launchUrl(Uri.parse(cfg.announcementUrl!),
                              mode: LaunchMode.externalApplication),
                    ),
                  ),
                if (cfg.showStats && store.all.isNotEmpty)
                  SliverToBoxAdapter(child: _Stats(store: store)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: SegmentedButton<TaskFilter>(
                      segments: [
                        ButtonSegment(
                            value: TaskFilter.all,
                            label: Text('الكل (${store.all.length})')),
                        ButtonSegment(
                            value: TaskFilter.active,
                            label: Text('الحالية (${store.activeCount})')),
                        ButtonSegment(
                            value: TaskFilter.done,
                            label: Text('المكتملة (${store.doneCount})')),
                      ],
                      selected: {store.filter},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => store.setFilter(s.first),
                    ),
                  ),
                ),
                if (!store.loaded)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(message: cfg.emptyMessage),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 96),
                    sliver: SliverList.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, i) {
                        final t = tasks[i];
                        return _TaskTile(
                          key: ValueKey(t.id),
                          task: t,
                          showPriority: cfg.showPriority,
                          onToggle: () => store.toggle(t),
                          onTap: () => _edit(context, t),
                          onDelete: () => _delete(context, t),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClearDone(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف المهام المكتملة؟'),
        content: Text('سيتم حذف ${store.doneCount} مهمة مكتملة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) await store.clearDone();
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    super.key,
    required this.task,
    required this.showPriority,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final Task task;
  final bool showPriority;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color _priorityColor(ColorScheme cs) => switch (task.priority) {
        Priority.high => Colors.red,
        Priority.normal => cs.primary,
        Priority.low => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final overdue = task.dueDate != null &&
        !task.done &&
        task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));

    return Dismissible(
      key: ValueKey('d-${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: cs.errorContainer,
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          onTap: onTap,
          leading: Checkbox(
            value: task.done,
            onChanged: (_) => onToggle(),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.done ? TextDecoration.lineThrough : null,
              color: task.done ? cs.outline : null,
            ),
          ),
          subtitle: (task.note.isEmpty && task.dueDate == null)
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.note.isNotEmpty)
                      Text(task.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(Icons.event,
                              size: 14, color: overdue ? cs.error : cs.outline),
                          const SizedBox(width: 4),
                          Text(
                            '${task.dueDate!.year}/${task.dueDate!.month}/${task.dueDate!.day}'
                            '${overdue ? ' • متأخرة' : ''}',
                            style: TextStyle(
                                fontSize: 12, color: overdue ? cs.error : cs.outline),
                          ),
                        ]),
                      ),
                  ],
                ),
          trailing: showPriority
              ? Tooltip(
                  message: 'الأولوية: ${task.priority.label}',
                  child: Icon(Icons.flag,
                      color: task.done ? cs.outlineVariant : _priorityColor(cs)),
                )
              : null,
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.store});
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final total = store.all.length;
    final progress = total == 0 ? 0.0 : store.doneCount / total;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('التقدّم', style: tt.titleMedium),
                const Spacer(),
                Text('${(progress * 100).round()}%', style: tt.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text('${store.doneCount} من $total مهمة مكتملة', style: tt.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rtl, size: 72, color: cs.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
