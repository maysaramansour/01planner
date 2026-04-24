import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/event.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'widget_service.dart';

class EventService {
  EventService._internal();
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;

  Box<Event> get _box => StorageService().events;

  ValueListenable<Box<Event>> watchAll() => _box.listenable();

  List<Event> all() => _box.values.toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));

  bool _occursOn(Event e, DateTime day) {
    final d0 = DateTime(day.year, day.month, day.day);
    final start = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
    if (d0.isBefore(start)) return false;
    switch (e.recurrence) {
      case 0:
        return d0.isAtSameMomentAs(start);
      case 1:
        return true;
      case 2:
        return d0.weekday == e.startAt.weekday;
      case 3:
        return d0.day == e.startAt.day;
      default:
        return false;
    }
  }

  List<Event> eventsForDay(DateTime day) =>
      all().where((e) => _occursOn(e, day)).toList();

  List<Event> eventsForRange(DateTime start, DateTime end) {
    final list = <Event>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(last)) {
      list.addAll(eventsForDay(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return list;
  }

  Future<void> add(Event event) async {
    await _box.put(event.id, event);
    await NotificationService().scheduleEvent(event);
    await WidgetService().refresh();
  }

  Future<void> update(Event event) async {
    await _box.put(event.id, event);
    await NotificationService().scheduleEvent(event);
    await WidgetService().refresh();
  }

  Future<void> delete(String id) async {
    final e = _box.get(id);
    if (e?.notificationId != null) {
      await NotificationService().cancel(e!.notificationId!);
    }
    await _box.delete(id);
    await WidgetService().refresh();
  }
}
