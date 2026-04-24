import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';

import '../models/goal.dart';
import '../services/goal_service.dart';

class GoalEditScreen extends StatefulWidget {
  final Goal? existing;
  const GoalEditScreen({super.key, this.existing});

  @override
  State<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends State<GoalEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _title = TextEditingController(text: g?.title ?? '');
    _description = TextEditingController(text: g?.description ?? '');
    _targetDate = g?.targetDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.title)));
      return;
    }
    final existing = widget.existing;
    final goal = existing ??
        Goal(id: const Uuid().v4(), title: '', createdAt: DateTime.now());
    goal.title = _title.text.trim();
    goal.description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    goal.targetDate = _targetDate;
    if (existing == null) {
      await GoalService().add(goal);
    } else {
      await GoalService().update(goal);
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
    await GoalService().delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final dateLabel = _targetDate == null
        ? l.noDueDate
        : intl.DateFormat.yMMMd(lang).format(_targetDate!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l.addGoal : l.editGoal),
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
            controller: _description,
            maxLines: 4,
            decoration: InputDecoration(labelText: l.description),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            leading: const Icon(Icons.flag_outlined),
            title: Text(l.targetDate),
            subtitle: Text(dateLabel),
            trailing: _targetDate == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _targetDate = null),
                  ),
            onTap: () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                context: context,
                initialDate: _targetDate ?? now,
                firstDate: now.subtract(const Duration(days: 30)),
                lastDate: now.add(const Duration(days: 365 * 10)),
                locale: Locale(lang),
              );
              if (d != null) setState(() => _targetDate = d);
            },
          ),
        ],
      ),
    );
  }
}
