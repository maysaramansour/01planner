import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/ai_service.dart';
import '../services/task_service.dart';
import 'task_icons.dart';

class AIQuickAddBar extends StatefulWidget {
  const AIQuickAddBar({super.key});

  @override
  State<AIQuickAddBar> createState() => _AIQuickAddBarState();
}

class _AIQuickAddBarState extends State<AIQuickAddBar> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    final parsed = await AIService().parseTask(text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.aiUnavailable)),
      );
      return;
    }
    final confirmed = await _showConfirmSheet(parsed);
    if (confirmed != true) return;
    final task = Task(
      id: const Uuid().v4(),
      title: parsed.title,
      createdAt: DateTime.now(),
      scheduledStart: parsed.scheduledStart,
      durationMinutes: parsed.durationMinutes ??
          (parsed.scheduledStart != null ? 30 : null),
      iconKey: parsed.iconKey,
      colorValue: parsed.colorValue,
      subtasks: parsed.subtasks
          .map((s) => s.startsWith('[') ? s : '[ ] $s')
          .toList(),
      notes: parsed.notes,
      reminderEnabled: parsed.scheduledStart != null,
      reminderLeadMinutes: 10,
    );
    await TaskService().add(task);
    _controller.clear();
  }

  Future<bool?> _showConfirmSheet(ParsedTask parsed) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final color = parsed.colorValue != null ? Color(parsed.colorValue!) : cs.primary;
    final timeLabel = parsed.scheduledStart == null
        ? l.inbox
        : '${parsed.scheduledStart}'.split('.').first;
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(TaskIcons.iconFor(parsed.iconKey),
                      color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      parsed.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${l.startTime}: $timeLabel',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              if (parsed.durationMinutes != null)
                Text('${l.duration}: ${parsed.durationMinutes} min',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              if (parsed.subtasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l.subtasks,
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1)),
                const SizedBox(height: 4),
                for (final s in parsed.subtasks)
                  Text('• $s',
                      style:
                          TextStyle(color: cs.onSurface, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: l.quickAddHint,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.send, size: 18),
                onPressed: _submit,
              ),
          ],
        ),
      ),
    );
  }
}
