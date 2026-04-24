import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';

import '../services/ai_chat_service.dart';
import '../services/ai_config.dart';
import '../services/app_prefs.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';

class AdvancedScreen extends StatelessWidget {
  const AdvancedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.advanced)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _firstDayRow(context, l, cs),
          const SizedBox(height: 16),
          _workHoursRow(context, l, cs),
          const SizedBox(height: 16),
          _weekendRow(context, l, cs),
          const SizedBox(height: 16),
          _languageRow(context, l, cs),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(l.languageHint,
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 12)),
          ),
          const SizedBox(height: 36),
          _resetRow(context, l, cs),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(l.resetAppWarning,
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _firstDayRow(BuildContext context, AppLocalizations l, ColorScheme cs) {
    final weekdays = {
      1: l.monday,
      2: l.tuesday,
      3: l.wednesday,
      4: l.thursday,
      5: l.friday,
      6: l.saturday,
      7: l.sunday,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: cs.onSurface),
          const SizedBox(width: 12),
          Expanded(
              child: Text(l.firstDayOfWeek,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600))),
          ValueListenableBuilder<int>(
            valueListenable: AppPrefs().firstDayOfWeek,
            builder: (context, current, _) => DropdownButton<int>(
              value: current,
              underline: const SizedBox.shrink(),
              items: [
                for (final e in weekdays.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) {
                if (v != null) AppPrefs().setFirstDayOfWeek(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _workHoursRow(BuildContext context, AppLocalizations l, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: cs.onSurface),
          const SizedBox(width: 12),
          Expanded(
              child: Text(l.availableHours,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600))),
          ValueListenableBuilder<int>(
            valueListenable: AppPrefs().workStartHour,
            builder: (context, s, _) => ValueListenableBuilder<int>(
              valueListenable: AppPrefs().workEndHour,
              builder: (context, e, _) => TextButton(
                onPressed: () async {
                  final start = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: s, minute: 0),
                  );
                  if (start == null || !context.mounted) return;
                  final end = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: e, minute: 0),
                  );
                  if (end == null) return;
                  final newStart = start.hour;
                  final newEnd = end.hour == 0 ? 24 : end.hour;
                  await AppPrefs().setWorkHours(
                      startHour: newStart, endHour: newEnd);
                },
                child: Text(
                  '${s.toString().padLeft(2, '0')}:00 – ${e.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekendRow(BuildContext context, AppLocalizations l, ColorScheme cs) {
    final names = {
      1: l.monday,
      2: l.tuesday,
      3: l.wednesday,
      4: l.thursday,
      5: l.friday,
      6: l.saturday,
      7: l.sunday,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.weekend_outlined, color: cs.onSurface),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(l.weekendDays,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<int>>(
            valueListenable: AppPrefs().weekendDays,
            builder: (context, selected, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in [1, 2, 3, 4, 5, 6, 7])
                  FilterChip(
                    label: Text(names[d]!),
                    selected: selected.contains(d),
                    onSelected: (on) {
                      final next = List<int>.from(selected);
                      if (on) {
                        next.add(d);
                      } else {
                        next.remove(d);
                      }
                      AppPrefs().setWeekendDays(next);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageRow(BuildContext context, AppLocalizations l, ColorScheme cs) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService().notifier,
      builder: (context, current, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.translate, color: cs.onSurface),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(l.language,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600))),
              DropdownButton<String>(
                value: current.languageCode,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: 'en', child: Text(l.english)),
                  DropdownMenuItem(value: 'ar', child: Text(l.arabic)),
                ],
                onChanged: (v) {
                  if (v != null) LocaleService().setLocale(Locale(v));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resetRow(BuildContext context, AppLocalizations l, ColorScheme cs) {
    return Material(
      color: cs.error.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _confirmReset(context, l),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.delete_forever, color: cs.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.resetApp,
                  style: TextStyle(
                      color: cs.error,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmReset),
        content: Text(l.resetAppWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.resetApp)),
        ],
      ),
    );
    if (ok != true) return;
    await StorageService().tasks.clear();
    await StorageService().events.clear();
    await StorageService().habits.clear();
    await StorageService().completions.clear();
    await StorageService().goals.clear();
    await StorageService().aiMessages.clear();
    await StorageService().chatSessions.clear();
    await AIChatService().init();
    await AIConfig().init();
    await AppPrefs().resetAll();
    if (context.mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}
