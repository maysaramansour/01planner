import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../services/event_service.dart';

class EventEditScreen extends StatefulWidget {
  final Event? existing;
  final DateTime? initialDate;
  const EventEditScreen({super.key, this.existing, this.initialDate});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late DateTime _startAt;
  late DateTime _endAt;
  int _leadMinutes = 15;
  int _recurrence = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    final base = widget.initialDate ?? DateTime.now();
    final defaultStart =
        DateTime(base.year, base.month, base.day, DateTime.now().hour + 1);
    _startAt = e?.startAt ?? defaultStart;
    _endAt = e?.endAt ?? defaultStart.add(const Duration(hours: 1));
    _leadMinutes = e?.reminderLeadMinutes ?? 15;
    _recurrence = e?.recurrence ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final lang = Localizations.localeOf(context).languageCode;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: Locale(lang),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.title)));
      return;
    }
    if (_endAt.isBefore(_startAt)) _endAt = _startAt.add(const Duration(hours: 1));
    final existing = widget.existing;
    final event = existing ??
        Event(
          id: const Uuid().v4(),
          title: '',
          startAt: _startAt,
          endAt: _endAt,
          createdAt: DateTime.now(),
        );
    event.title = _title.text.trim();
    event.location =
        _location.text.trim().isEmpty ? null : _location.text.trim();
    event.startAt = _startAt;
    event.endAt = _endAt;
    event.reminderLeadMinutes = _leadMinutes;
    event.recurrence = _recurrence;
    if (existing == null) {
      await EventService().add(event);
    } else {
      await EventService().update(event);
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
    await EventService().delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final fmt = intl.DateFormat.yMMMd(lang).add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l.addEvent : l.editEvent),
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
            controller: _title,
            decoration: InputDecoration(labelText: l.title),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: InputDecoration(labelText: l.location),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            leading: const Icon(Icons.play_arrow),
            title: Text(l.startDate),
            subtitle: Text(fmt.format(_startAt)),
            onTap: () async {
              final d = await _pickDateTime(_startAt);
              if (d != null) setState(() => _startAt = d);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            leading: const Icon(Icons.stop),
            title: Text(l.endDate),
            subtitle: Text(fmt.format(_endAt)),
            onTap: () async {
              final d = await _pickDateTime(_endAt);
              if (d != null) setState(() => _endAt = d);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _recurrence,
            decoration: InputDecoration(labelText: l.recurrence),
            items: [
              DropdownMenuItem(value: 0, child: Text(l.recurrenceNone)),
              DropdownMenuItem(value: 1, child: Text(l.recurrenceDaily)),
              DropdownMenuItem(value: 2, child: Text(l.recurrenceWeekly)),
              DropdownMenuItem(value: 3, child: Text(l.recurrenceMonthly)),
            ],
            onChanged: (v) => setState(() => _recurrence = v ?? 0),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _leadMinutes,
            decoration: InputDecoration(labelText: l.reminderLeadMinutes),
            items: const [0, 5, 10, 15, 30, 60, 120]
                .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                .toList(),
            onChanged: (v) => setState(() => _leadMinutes = v ?? 15),
          ),
        ],
      ),
    );
  }
}
