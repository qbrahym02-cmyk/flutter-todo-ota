import 'package:flutter/material.dart';

import '../models/task.dart';

/// نافذة سفلية لإضافة مهمة أو تعديلها.
Future<Task?> showTaskEditor(
  BuildContext context, {
  Task? initial,
  bool showPriority = true,
}) {
  return showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _TaskEditor(initial: initial, showPriority: showPriority),
    ),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({this.initial, required this.showPriority});
  final Task? initial;
  final bool showPriority;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _note = TextEditingController(text: widget.initial?.note);
  late Priority _priority = widget.initial?.priority ?? Priority.normal;
  late DateTime? _due = widget.initial?.dueDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.initial;
    final task = base == null
        ? Task(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: _title.text.trim(),
            note: _note.text.trim(),
            priority: _priority,
            createdAt: DateTime.now(),
            dueDate: _due,
          )
        : base.copyWith(
            title: _title.text.trim(),
            note: _note.text.trim(),
            priority: _priority,
            dueDate: _due,
            clearDueDate: _due == null,
          );
    Navigator.pop(context, task);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) setState(() => _due = d);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'تعديل المهمة' : 'مهمة جديدة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              autofocus: !editing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب عنوان المهمة' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.showPriority) ...[
              const SizedBox(height: 16),
              SegmentedButton<Priority>(
                segments: [
                  for (final p in Priority.values)
                    ButtonSegment(value: p, label: Text(p.label)),
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(_due == null
                        ? 'تاريخ الاستحقاق'
                        : '${_due!.year}/${_due!.month}/${_due!.day}'),
                  ),
                ),
                if (_due != null)
                  IconButton(
                    tooltip: 'إزالة التاريخ',
                    onPressed: () => setState(() => _due = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(editing ? Icons.save : Icons.add),
              label: Text(editing ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}
