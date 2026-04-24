import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/new_task_sheet.dart';
import '../widgets/task_icons.dart';
import 'task_edit_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.inbox)),
      body: ValueListenableBuilder(
        valueListenable: TaskService().watchAll(),
        builder: (context, Box<Task> _, __) {
          final tasks = TaskService().inbox();
          if (tasks.isEmpty) {
            return _EmptyState(onAdd: () => _openNew(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _InboxTile(
              task: tasks[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => TaskEditScreen(existing: tasks[i])),
              ),
              onLongPress: () => _confirmDelete(context, tasks[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNew(BuildContext context) async {
    await showNewTaskSheet(context);
  }

  Future<void> _confirmDelete(BuildContext context, Task t) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.no)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.yes)),
        ],
      ),
    );
    if (ok == true) await TaskService().delete(t.id);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 64,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inbox, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              l.inboxEmptyTitle,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              l.inboxEmptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: const Icon(Icons.add_circle),
                label: Text(l.newInboxTask),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _InboxTile({
    required this.task,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = task.colorValue != null ? Color(task.colorValue!) : cs.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(TaskIcons.iconFor(task.iconKey),
                    color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.notes != null && task.notes!.isNotEmpty)
                      Text(
                        task.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Checkbox(
                value: task.completed,
                onChanged: (_) => TaskService().toggleComplete(task.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
