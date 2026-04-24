import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;

import '../models/event.dart';
import '../models/task.dart';
import '../services/app_prefs.dart';
import 'task_icons.dart';

enum _Kind { task, event, anchorStart, anchorEnd }

class _Item {
  final _Kind kind;
  final Task? task;
  final Event? event;
  final DateTime start;
  final int durationMinutes;
  _Item._(this.kind,
      {this.task,
      this.event,
      required this.start,
      required this.durationMinutes});

  factory _Item.task(Task t) => _Item._(
        _Kind.task,
        task: t,
        start: t.scheduledStart!,
        durationMinutes: t.durationMinutes ?? 30,
      );

  factory _Item.event(Event e) {
    final duration =
        e.endAt.difference(e.startAt).inMinutes.clamp(5, 60 * 24).toInt();
    return _Item._(_Kind.event,
        event: e, start: e.startAt, durationMinutes: duration);
  }

  factory _Item.anchor(DateTime when, bool isStart) => _Item._(
        isStart ? _Kind.anchorStart : _Kind.anchorEnd,
        start: when,
        durationMinutes: 0,
      );

  DateTime get end => start.add(Duration(minutes: durationMinutes));
}

class TimelineView extends StatefulWidget {
  final List<Task> scheduledTasks;
  final List<Event> events;
  final DateTime day;
  final void Function(Task) onTapTask;
  final void Function(Task) onLongPressTask;
  final void Function(Event) onTapEvent;
  final VoidCallback onAddTask;
  final Widget? footer;
  const TimelineView({
    super.key,
    required this.scheduledTasks,
    required this.events,
    required this.day,
    required this.onTapTask,
    required this.onLongPressTask,
    required this.onTapEvent,
    required this.onAddTask,
    this.footer,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  Timer? _nowTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nowTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppPrefs().layoutMode,
      builder: (context, layout, _) => ValueListenableBuilder<int>(
        valueListenable: AppPrefs().workStartHour,
        builder: (context, startH, _) => ValueListenableBuilder<int>(
          valueListenable: AppPrefs().workEndHour,
          builder: (context, endH, _) => _build(context, layout, startH, endH),
        ),
      ),
    );
  }

  Widget _build(BuildContext context, String layout, int startH, int endH) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isToday = _sameDay(widget.day, _now);

    // Rise-and-shine + Wind-down anchors for the active day.
    final wake =
        DateTime(widget.day.year, widget.day.month, widget.day.day, startH, 0);
    final sleep = DateTime(widget.day.year, widget.day.month, widget.day.day,
        endH >= 24 ? 23 : endH, endH >= 24 ? 55 : 0);

    final items = <_Item>[];
    items.add(_Item.anchor(wake, true));
    for (final e in widget.events) {
      items.add(_Item.event(e));
    }
    for (final t in widget.scheduledTasks) {
      if (t.scheduledStart != null) items.add(_Item.task(t));
    }
    items.add(_Item.anchor(sleep, false));
    items.sort((a, b) => a.start.compareTo(b.start));

    // Find index of first item that starts after now, for inserting a
    // countdown row.
    int? countdownAfterIndex;
    if (isToday) {
      for (var i = 0; i < items.length - 1; i++) {
        if (!items[i].end.isAfter(_now) && items[i + 1].start.isAfter(_now)) {
          countdownAfterIndex = i;
          break;
        }
      }
    }

    final showSubtitles = layout == 'full';

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: items.length + (widget.footer != null ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= items.length) return widget.footer!;
        final item = items[i];
        final isLast = i == items.length - 1;
        final children = <Widget>[];
        children.add(_itemRow(item, cs, showSubtitles, l));

        if (!isLast) {
          // Dashed connector for some vertical visual continuity.
          children.add(_connectorRow(cs, _connectorColor(item, cs)));
        }

        if (countdownAfterIndex != null && i == countdownAfterIndex) {
          children.add(_countdownRow(cs, l, items[i + 1]));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  Color _connectorColor(_Item it, ColorScheme cs) {
    switch (it.kind) {
      case _Kind.anchorStart:
        return cs.primary;
      case _Kind.anchorEnd:
        return cs.onSurfaceVariant;
      case _Kind.task:
        return (it.task?.colorValue != null
                ? Color(it.task!.colorValue!)
                : cs.primary)
            .withValues(alpha: 0.5);
      case _Kind.event:
        return cs.tertiary.withValues(alpha: 0.5);
    }
  }

  Widget _itemRow(
      _Item it, ColorScheme cs, bool showSubtitles, AppLocalizations l) {
    final timeFmt = intl.DateFormat.Hm(Localizations.localeOf(context).languageCode);
    final timeStr = timeFmt.format(it.start);

    String title = '';
    String? subtitle;
    IconData icon = Icons.check_circle_outline;
    Color color = cs.primary;
    bool completed = false;
    bool isAnchor = false;
    VoidCallback? onTap;
    VoidCallback? onLongPress;

    switch (it.kind) {
      case _Kind.anchorStart:
        title = l.riseAndShine;
        icon = Icons.alarm;
        color = cs.primary;
        isAnchor = true;
        break;
      case _Kind.anchorEnd:
        title = l.windDown;
        icon = Icons.nightlight_round;
        color = cs.tertiary;
        isAnchor = true;
        break;
      case _Kind.task:
        final t = it.task!;
        title = t.title;
        subtitle = t.notes ?? t.description;
        icon = TaskIcons.iconFor(t.iconKey);
        color = t.colorValue != null ? Color(t.colorValue!) : cs.primary;
        completed = t.completed;
        onTap = () => widget.onTapTask(t);
        onLongPress = () => widget.onLongPressTask(t);
        break;
      case _Kind.event:
        final e = it.event!;
        title = e.title;
        subtitle = e.location;
        icon = Icons.event;
        color = cs.tertiary;
        onTap = () => widget.onTapEvent(e);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    timeStr,
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  width: isAnchor ? 56 : 40,
                  height: isAnchor ? 56 : 40,
                  decoration: BoxDecoration(
                    color: isAnchor
                        ? (it.kind == _Kind.anchorStart
                            ? color
                            : cs.surfaceContainerHighest)
                        : color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isAnchor && it.kind == _Kind.anchorEnd
                        ? cs.tertiary
                        : Colors.white,
                    size: isAnchor ? 26 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (it.kind == _Kind.task || it.kind == _Kind.event)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(timeStr,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 11)),
                        ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isAnchor ? 18 : 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (showSubtitles &&
                          subtitle != null &&
                          subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isAnchor)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: it.kind == _Kind.anchorStart
                            ? cs.primary
                            : cs.tertiary,
                        width: 2,
                      ),
                    ),
                  )
                else
                  Icon(
                    completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: completed ? cs.onSurface : cs.onSurfaceVariant,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _connectorRow(ColorScheme cs, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 52 + 18),
      child: SizedBox(
        height: 16,
        child: CustomPaint(
          painter: _DashedVLinePainter(color: color),
        ),
      ),
    );
  }

  Widget _countdownRow(ColorScheme cs, AppLocalizations l, _Item next) {
    final diff = next.start.difference(_now);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final label = h > 0 ? '${h}h ${m}m' : '${m}m';
    final target = next.kind == _Kind.anchorEnd ? l.windDown : next.task?.title ?? next.event?.title ?? l.nextItem;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 52),
              Icon(Icons.schedule, color: cs.onSurfaceVariant, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    children: [
                      TextSpan(text: '${l.youveGot} '),
                      TextSpan(
                          text: label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      TextSpan(text: ' ${l.tilNext(target)}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: widget.onAddTask,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.onSurface,
                  foregroundColor: cs.surface,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.add_circle, size: 18),
                label: Text(l.addTask),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedVLinePainter extends CustomPainter {
  final Color color;
  _DashedVLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashH = 3.0;
    const gapH = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    double y = 0;
    final x = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashH), paint);
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedVLinePainter old) => old.color != color;
}
