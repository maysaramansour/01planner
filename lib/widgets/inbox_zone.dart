import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';

import '../models/task.dart';
import 'task_icons.dart';

class InboxZone extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onTap;
  final void Function(Task) onLongPress;
  const InboxZone({
    super.key,
    required this.tasks,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.surfaceContainerHighest),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  l.inbox.toUpperCase(),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = tasks[i];
                final color = t.colorValue != null
                    ? Color(t.colorValue!)
                    : cs.primary;
                return InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => onTap(t),
                  onLongPress: () => onLongPress(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: color.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(TaskIcons.iconFor(t.iconKey),
                            size: 16, color: color),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            t.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface,
                              decoration: t.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
