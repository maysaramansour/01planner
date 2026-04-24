import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/event.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../services/ai_config.dart';
import '../services/event_service.dart';
import '../services/goal_service.dart';
import '../services/locale_service.dart';
import '../services/task_service.dart';
import 'advanced_screen.dart';
import 'ai_settings_screen.dart';
import 'calendar_screen.dart';
import 'customization_screen.dart';
import 'daily_planner_screen.dart';
import 'goals_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ValueListenableBuilder(
        valueListenable: TaskService().watchAll(),
        builder: (context, Box<Task> _, __) {
          return ValueListenableBuilder(
            valueListenable: EventService().watchAll(),
            builder: (context, Box<Event> _, __) {
              return ValueListenableBuilder(
                valueListenable: GoalService().watchAll(),
                builder: (context, Box<Goal> _, __) {
                  return _buildList(context, l, cs);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations l, ColorScheme cs) {
    final tasksAll = TaskService().all();
    final inboxCount = TaskService().inbox().length;
    final todayTaskCount = TaskService().scheduledForDay(DateTime.now()).length;
    final todayEventCount = EventService().eventsForDay(DateTime.now()).length;
    final goalsCount = GoalService().all().length;
    final completedCount = tasksAll.where((t) => t.completed).length;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Summary row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: _statCard(
                    cs, Icons.today_outlined, todayTaskCount, l.todayStat),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                    cs, Icons.inbox_outlined, inboxCount, l.inboxStat),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(cs, Icons.check_circle_outline,
                    completedCount, l.doneStat),
              ),
            ],
          ),
        ),
        _section(cs, l.organize),
        _navTile(
          icon: Icons.calendar_month_outlined,
          title: l.calendar,
          count: todayEventCount,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          ),
        ),
        _navTile(
          icon: Icons.flag_outlined,
          title: l.goals,
          count: goalsCount,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GoalsScreen()),
          ),
        ),
        _navTile(
          icon: Icons.auto_awesome_outlined,
          title: l.dailyPlan,
          subtitle: l.aiAssistantHint,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DailyPlannerScreen()),
          ),
        ),
        _section(cs, l.aiAssistant),
        ValueListenableBuilder<bool>(
          valueListenable: AIConfig().enabled,
          builder: (context, enabled, _) => _navTile(
            icon: Icons.smart_toy_outlined,
            title: l.aiAssistant,
            subtitle: enabled ? l.aiEnabled : l.aiDisabledHint,
            trailingDot: enabled ? cs.primary : cs.onSurfaceVariant,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AISettingsScreen()),
            ),
          ),
        ),
        _section(cs, l.preferences),
        ValueListenableBuilder<Locale>(
          valueListenable: LocaleService().notifier,
          builder: (context, current, _) => ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l.language),
            trailing: DropdownButton<String>(
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
          ),
        ),
        _navTile(
          icon: Icons.notifications_outlined,
          title: l.notificationsAndAlerts,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        _navTile(
          icon: Icons.palette_outlined,
          title: l.customization,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomizationScreen()),
          ),
        ),
        _navTile(
          icon: Icons.tune_outlined,
          title: l.advanced,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdvancedScreen()),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statCard(ColorScheme cs, IconData icon, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(height: 4),
          Text('$count',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _section(ColorScheme cs, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1),
        ),
      );

  Widget _navTile({
    required IconData icon,
    required String title,
    String? subtitle,
    int? count,
    Color? trailingDot,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null && count > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          if (trailingDot != null) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: trailingDot, shape: BoxShape.circle),
            ),
          ],
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
