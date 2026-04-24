import 'app_prefs.dart';
import 'event_service.dart';
import 'task_service.dart';

/// A single busy block (event or scheduled task), used for conflict checks
/// and free-slot searches.
class BusyBlock {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String kind; // 'task' | 'event'
  const BusyBlock({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.kind,
  });
}

class SchedulingService {
  SchedulingService._internal();
  static final SchedulingService _instance = SchedulingService._internal();
  factory SchedulingService() => _instance;

  /// All busy blocks in the given window (defaults to a generous +/- range).
  List<BusyBlock> busyBlocks({
    DateTime? from,
    DateTime? to,
  }) {
    final start = from ?? DateTime.now().subtract(const Duration(days: 1));
    final end = to ?? DateTime.now().add(const Duration(days: 365));
    final out = <BusyBlock>[];
    for (final e in EventService().eventsForRange(start, end)) {
      out.add(BusyBlock(
        id: e.id,
        title: e.title,
        start: e.startAt,
        end: e.endAt,
        kind: 'event',
      ));
    }
    for (final t in TaskService().all()) {
      final s = t.scheduledStart;
      if (s == null) continue;
      if (s.isBefore(start) || s.isAfter(end)) continue;
      final dur = t.durationMinutes ?? 30;
      out.add(BusyBlock(
        id: t.id,
        title: t.title,
        start: s,
        end: s.add(Duration(minutes: dur)),
        kind: 'task',
      ));
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  /// Busy blocks that overlap `[start, start + duration)`, optionally
  /// excluding a specific task or event id (used when the user is editing
  /// that very item).
  List<BusyBlock> conflictsFor({
    required DateTime start,
    required int durationMinutes,
    String? excludeTaskId,
    String? excludeEventId,
  }) {
    final end = start.add(Duration(minutes: durationMinutes));
    final blocks = busyBlocks(
      from: start.subtract(const Duration(days: 1)),
      to: end.add(const Duration(days: 1)),
    );
    return blocks.where((b) {
      if (b.kind == 'task' && b.id == excludeTaskId) return false;
      if (b.kind == 'event' && b.id == excludeEventId) return false;
      // Two ranges overlap when each starts before the other ends.
      return b.start.isBefore(end) && b.end.isAfter(start);
    }).toList();
  }

  /// First free slot of at least `durationMinutes` starting at or after
  /// `after`. Returns null only if no free slot is found within [lookAheadDays].
  /// A 5-min buffer is left between adjacent blocks. Respects the user's
  /// work-hour window and skips weekend days from [AppPrefs].
  DateTime? nextFreeSlot({
    required DateTime after,
    required int durationMinutes,
    String? excludeTaskId,
    String? excludeEventId,
    int lookAheadDays = 30,
  }) {
    const buffer = Duration(minutes: 5);
    final end = after.add(Duration(days: lookAheadDays));
    final blocks = busyBlocks(from: after, to: end)
        .where((b) => !(b.kind == 'task' && b.id == excludeTaskId) &&
            !(b.kind == 'event' && b.id == excludeEventId))
        .toList();

    final startHour = AppPrefs().workStartHour.value;
    final endHour = AppPrefs().workEndHour.value;
    final weekend = AppPrefs().weekendDays.value;

    DateTime nextWorkStart(DateTime d) {
      var c = DateTime(d.year, d.month, d.day, startHour, 0);
      while (weekend.contains(c.weekday)) {
        c = c.add(const Duration(days: 1));
      }
      return c;
    }

    DateTime shiftIntoWindow(DateTime cursor) {
      // Skip weekends.
      while (weekend.contains(cursor.weekday)) {
        cursor = DateTime(cursor.year, cursor.month, cursor.day + 1,
            startHour, 0);
      }
      // Before work starts → move to start of work.
      if (cursor.hour < startHour) {
        cursor = DateTime(cursor.year, cursor.month, cursor.day, startHour, 0);
      }
      // After work ends → jump to next working day.
      if (cursor.hour >= endHour) {
        cursor = nextWorkStart(cursor.add(const Duration(days: 1)));
      }
      return cursor;
    }

    bool fitsInWindow(DateTime cursor) {
      final cutoff = DateTime(cursor.year, cursor.month, cursor.day, endHour, 0);
      return cursor.add(Duration(minutes: durationMinutes)).isBefore(cutoff) ||
          cursor.add(Duration(minutes: durationMinutes))
              .isAtSameMomentAs(cutoff);
    }

    var cursor = shiftIntoWindow(after);
    var blockIndex = 0;
    final stopAt = after.add(Duration(days: lookAheadDays));

    while (cursor.isBefore(stopAt)) {
      cursor = shiftIntoWindow(cursor);
      if (!fitsInWindow(cursor)) {
        cursor = nextWorkStart(
            cursor.add(const Duration(days: 1)));
        continue;
      }
      // Advance blockIndex past any blocks already behind `cursor`.
      while (blockIndex < blocks.length &&
          !blocks[blockIndex].end.isAfter(cursor)) {
        blockIndex++;
      }
      if (blockIndex >= blocks.length) return cursor;
      final b = blocks[blockIndex];
      if (cursor.add(Duration(minutes: durationMinutes)).isBefore(b.start) ||
          cursor
              .add(Duration(minutes: durationMinutes))
              .isAtSameMomentAs(b.start)) {
        return cursor;
      }
      // Current slot overlaps b; skip past b.
      cursor = b.end.add(buffer);
    }
    return null;
  }
}
