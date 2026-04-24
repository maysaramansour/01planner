import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/ai_service.dart';
import '../services/scheduling_service.dart';
import '../services/task_service.dart';
import 'icon_picker_sheet.dart';
import 'task_icons.dart';

Future<void> showNewTaskSheet(BuildContext context,
    {DateTime? suggestedStart, bool inbox = true}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _NewTaskSheet(
      suggestedStart: suggestedStart,
      inbox: inbox,
    ),
  );
}

class _NewTaskSheet extends StatefulWidget {
  final DateTime? suggestedStart;
  final bool inbox;
  const _NewTaskSheet({this.suggestedStart, this.inbox = true});

  @override
  State<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<_NewTaskSheet> {
  final _title = TextEditingController();
  String _iconKey = 'call';
  int _colorValue = kPaletteColors.first;
  int _step = 0;
  DateTime? _start;
  int _durationMinutes = 30;

  static const _quickTemplates = [
    ('call', 'Answer Emails', 15),
    ('shop', 'Watch a Movie', 90),
    ('meet', 'Meet with Friends', 60),
    ('gym', 'Go for a Run', 45),
  ];

  @override
  void initState() {
    super.initState();
    _start = widget.suggestedStart;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_title.text.trim().isEmpty) return;
    if (widget.inbox && _step == 0) {
      setState(() => _step = 1);
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    final task = Task(
      id: const Uuid().v4(),
      title: _title.text.trim(),
      createdAt: DateTime.now(),
      scheduledStart: _start,
      durationMinutes: _start != null ? _durationMinutes : null,
      iconKey: _iconKey,
      colorValue: _colorValue,
      reminderEnabled: _start != null,
      reminderLeadMinutes: 10,
    );
    await TaskService().add(task);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickIcon() async {
    final pick = await showIconPickerSheet(
      context,
      initialIconKey: _iconKey,
      initialColorValue: _colorValue,
    );
    if (pick == null) return;
    setState(() {
      _iconKey = pick.iconKey;
      _colorValue = pick.colorValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l.newTaskHeader.split(' ')[0],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.newTaskHeader.split(' ').skip(1).join(' '),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_step == 0) ..._buildStep1(l, cs) else ..._buildStep2(l, cs),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _title.text.trim().isEmpty ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                    widget.inbox && _step == 0 ? l.newTaskContinue : l.save,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStep1(AppLocalizations l, ColorScheme cs) {
    return [
      Text(l.newTaskWhat,
          style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Row(
        children: [
          InkWell(
            onTap: _pickIcon,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                TaskIcons.iconFor(_iconKey),
                color: Color(_colorValue),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _title,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l.newTaskTitleHint,
                filled: false,
                border: UnderlineInputBorder(
                    borderSide: BorderSide(color: cs.primary)),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5))),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: cs.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              onSubmitted: (_) => _continue(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      for (final tpl in _quickTemplates)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TemplateCard(
            iconKey: tpl.$1,
            title: tpl.$2,
            durationMinutes: tpl.$3,
            onTap: () {
              setState(() {
                _iconKey = tpl.$1;
                _title.text = tpl.$2;
                _durationMinutes = tpl.$3;
              });
            },
          ),
        ),
    ];
  }

  List<Widget> _buildStep2(AppLocalizations l, ColorScheme cs) {
    return [
      Text(l.when,
          style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _start ?? DateTime.now(),
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365 * 2)),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (date == null || !mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: _start != null
                      ? TimeOfDay.fromDateTime(_start!)
                      : TimeOfDay.now(),
                );
                if (time == null) return;
                setState(() => _start = DateTime(
                    date.year, date.month, date.day, time.hour, time.minute));
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.startTime,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _start == null
                          ? l.inbox
                          : '${_start!.day}/${_start!.month} · ${TimeOfDay.fromDateTime(_start!).format(context)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButton<int>(
              value: _durationMinutes,
              underline: const SizedBox.shrink(),
              items: const [15, 30, 45, 60, 90, 120, 180]
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text('$m min')))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _durationMinutes = v ?? 30),
            ),
          ),
        ],
      ),
      _conflictBanner(l, cs),
    ];
  }

  Widget _conflictBanner(AppLocalizations l, ColorScheme cs) {
    final start = _start;
    if (start == null) return const SizedBox.shrink();
    final conflicts = SchedulingService().conflictsFor(
      start: start,
      durationMinutes: _durationMinutes,
    );
    if (conflicts.isEmpty) return const SizedBox.shrink();
    final lang = Localizations.localeOf(context).languageCode;
    final fmt = intl.DateFormat.Hm(lang);
    final summary = conflicts
        .take(2)
        .map((b) => '${fmt.format(b.start)} ${b.title}')
        .join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.conflictsWith(conflicts.length),
                      style: TextStyle(
                          color: cs.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurface, fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                final slot = SchedulingService().nextFreeSlot(
                  after: start,
                  durationMinutes: _durationMinutes,
                );
                if (slot != null) setState(() => _start = slot);
              },
              child: Text(l.findNextFree),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String iconKey;
  final String title;
  final int durationMinutes;
  final VoidCallback onTap;
  const _TemplateCard({
    required this.iconKey,
    required this.title,
    required this.durationMinutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeLabel = _sampleTimeRange(durationMinutes);
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(TaskIcons.iconFor(iconKey),
                  color: cs.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeLabel,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sampleTimeRange(int minutes) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour,
        (now.minute ~/ 15) * 15);
    final end = start.add(Duration(minutes: minutes));
    two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)} (${minutes}m)';
  }
}
