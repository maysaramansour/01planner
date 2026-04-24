import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';

class HabitEditScreen extends StatefulWidget {
  final Habit? existing;
  const HabitEditScreen({super.key, this.existing});

  @override
  State<HabitEditScreen> createState() => _HabitEditScreenState();
}

class _HabitEditScreenState extends State<HabitEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  int _frequencyType = 0;
  Set<int> _weekdays = {};
  TimeOfDay _reminder = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _name = TextEditingController(text: h?.name ?? '');
    _notes = TextEditingController(text: h?.notes ?? '');
    _frequencyType = h?.frequencyType ?? 0;
    _weekdays = (h?.weekdays ?? <int>[]).toSet();
    _reminder = TimeOfDay(
      hour: h?.reminderHour ?? 9,
      minute: h?.reminderMinute ?? 0,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.title)));
      return;
    }
    if (_frequencyType == 1 && _weekdays.isEmpty) {
      _frequencyType = 0;
    }
    final existing = widget.existing;
    final habit = existing ??
        Habit(id: const Uuid().v4(), name: '', createdAt: DateTime.now());
    habit.name = _name.text.trim();
    habit.notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    habit.frequencyType = _frequencyType;
    habit.weekdays =
        _frequencyType == 1 ? (_weekdays.toList()..sort()) : <int>[];
    habit.reminderHour = _reminder.hour;
    habit.reminderMinute = _reminder.minute;
    if (existing == null) {
      await HabitService().add(habit);
    } else {
      await HabitService().update(habit);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmDelete),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.no)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l.yes)),
        ],
      ),
    );
    if (confirmed != true) return;
    await HabitService().delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dayLabels = [
      l.monday,
      l.tuesday,
      l.wednesday,
      l.thursday,
      l.friday,
      l.saturday,
      l.sunday,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l.addHabit : l.editHabit),
        actions: [
          if (widget.existing != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.title),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(labelText: l.notes),
          ),
          const SizedBox(height: 16),
          Text(l.frequency,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(l.frequencyDaily)),
              ButtonSegment(value: 1, label: Text(l.frequencySpecificDays)),
            ],
            selected: {_frequencyType},
            onSelectionChanged: (s) => setState(() => _frequencyType = s.first),
          ),
          if (_frequencyType == 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final wd = i + 1;
                final selected = _weekdays.contains(wd);
                return FilterChip(
                  label: Text(dayLabels[i]),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _weekdays.add(wd);
                    } else {
                      _weekdays.remove(wd);
                    }
                  }),
                );
              }),
            ),
          ],
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            leading: const Icon(Icons.alarm_outlined),
            title: Text(l.reminder),
            subtitle: Text(_reminder.format(context)),
            onTap: () async {
              final t = await showTimePicker(
                  context: context, initialTime: _reminder);
              if (t != null) setState(() => _reminder = t);
            },
          ),
        ],
      ),
    );
  }
}
