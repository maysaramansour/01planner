import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';

import '../services/app_prefs.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final v = await NotificationService().areEnabled();
    if (mounted) setState(() => _enabled = v);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.notificationsAndAlerts)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(cs, Icons.notifications_active_outlined, l.alertsIntro),
          const SizedBox(height: 16),
          _statusTile(
            cs,
            Icons.notifications_outlined,
            l.enabledOnThisDevice,
            _enabled == null
                ? '…'
                : (_enabled! ? l.permissionGranted : l.permissionDenied),
            onTap: () async {
              await NotificationService().requestPermissions();
              await _refresh();
            },
          ),
          const SizedBox(height: 24),
          _sectionHeader(cs, l.alarms),
          _statusTile(
            cs,
            Icons.access_alarm_outlined,
            l.enabledOnThisDevice,
            l.alarmsHint,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _sectionHeader(cs, l.goalReminders),
          ValueListenableBuilder<bool>(
            valueListenable: AppPrefs().goalPulsesEnabled,
            builder: (context, enabled, _) => SwitchListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              tileColor: cs.surfaceContainerHighest,
              title: Text(l.goalPulsesTitle),
              subtitle: Text(l.goalPulsesSubtitle),
              value: enabled,
              onChanged: (v) => AppPrefs().setGoalPulsesEnabled(v),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader(cs, l.defaultAlerts),
          ValueListenableBuilder<List<int>>(
            valueListenable: AppPrefs().defaultAlerts,
            builder: (context, alerts, _) {
              return Column(
                children: [
                  for (var i = 0; i < alerts.length; i++)
                    _alertRow(cs, l, alerts[i], i),
                  _addAlertTile(cs, l),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
      );

  Widget _infoCard(ColorScheme cs, IconData icon, String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(color: cs.onSurface, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _statusTile(ColorScheme cs, IconData icon, String title,
      String subtitle,
      {VoidCallback? onTap}) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: cs.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(AppLocalizations l, int m) =>
      m == 0 ? l.atStartOfTask : l.minutesBeforeStart(m);

  Widget _alertRow(ColorScheme cs, AppLocalizations l, int m, int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, color: cs.onSurface),
            const SizedBox(width: 12),
            Expanded(child: Text(_labelFor(l, m))),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final next =
                    List<int>.from(AppPrefs().defaultAlerts.value)..removeAt(i);
                await AppPrefs().setDefaultAlerts(next);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _addAlertTile(ColorScheme cs, AppLocalizations l) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddAlertSheet(l),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(l.addNewAlert,
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAlertSheet(AppLocalizations l) async {
    final picks = [0, 5, 15, 30, 60, 120, 1440];
    final m = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in picks)
                ActionChip(
                  label: Text(_labelFor(l, p)),
                  onPressed: () => Navigator.pop(ctx, p),
                ),
            ],
          ),
        ),
      ),
    );
    if (m == null) return;
    final current = List<int>.from(AppPrefs().defaultAlerts.value);
    if (!current.contains(m)) current.add(m);
    await AppPrefs().setDefaultAlerts(current);
  }
}
