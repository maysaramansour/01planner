import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';

String encodeSubtask(String text, bool done) =>
    '${done ? "[x]" : "[ ]"} ${text.trim()}';

({String text, bool done}) decodeSubtask(String raw) {
  if (raw.startsWith('[x] ')) return (text: raw.substring(4), done: true);
  if (raw.startsWith('[ ] ')) return (text: raw.substring(4), done: false);
  return (text: raw, done: false);
}

class SubtaskEditor extends StatefulWidget {
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;
  const SubtaskEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<SubtaskEditor> createState() => _SubtaskEditorState();
}

class _SubtaskEditorState extends State<SubtaskEditor> {
  late final List<_SubtaskRow> _rows;
  final _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rows = widget.initial.map(_rowFromRaw).toList();
  }

  _SubtaskRow _rowFromRaw(String raw) {
    final d = decodeSubtask(raw);
    return _SubtaskRow(
      controller: TextEditingController(text: d.text),
      done: d.done,
    );
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    _addController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_rows
        .where((r) => r.controller.text.trim().isNotEmpty)
        .map((r) => encodeSubtask(r.controller.text, r.done))
        .toList());
  }

  void _add(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _rows.add(_SubtaskRow(
        controller: TextEditingController(text: trimmed),
        done: false,
      ));
      _addController.clear();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _rows.length; i++)
          Row(
            children: [
              Checkbox(
                value: _rows[i].done,
                onChanged: (v) {
                  setState(() => _rows[i].done = v ?? false);
                  _emit();
                },
              ),
              Expanded(
                child: TextField(
                  controller: _rows[i].controller,
                  decoration: const InputDecoration(
                      border: InputBorder.none, isDense: true),
                  onChanged: (_) => _emit(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: cs.onSurfaceVariant, size: 18),
                onPressed: () {
                  setState(() {
                    _rows[i].controller.dispose();
                    _rows.removeAt(i);
                  });
                  _emit();
                },
              ),
            ],
          ),
        Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.add, color: cs.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _addController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: l.addSubtask,
                ),
                onSubmitted: _add,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubtaskRow {
  final TextEditingController controller;
  bool done;
  _SubtaskRow({required this.controller, required this.done});
}
