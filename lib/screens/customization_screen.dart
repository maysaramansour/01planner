import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';

import '../services/app_prefs.dart';

class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.customization)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Preview(),
          const SizedBox(height: 24),
          _sectionHeader(context, l.appColor),
          const SizedBox(height: 8),
          const _ColorPalette(),
          const SizedBox(height: 12),
          Text(l.appColorHint,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12)),
          const SizedBox(height: 24),
          _sectionHeader(context, l.layout),
          const SizedBox(height: 8),
          const _LayoutToggle(),
          const SizedBox(height: 12),
          Text(l.layoutHint,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(text.toUpperCase(),
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1));
  }
}

class _Preview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<String>(
      valueListenable: AppPrefs().layoutMode,
      builder: (context, layout, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _row(cs, '13:00', Icons.work_outline, true, layout),
              _row(cs, '13:15', Icons.restaurant_outlined, true, layout),
              _gapRow(cs, layout),
              _row(cs, '14:00', Icons.call_outlined, true, layout),
            ],
          ),
        );
      },
    );
  }

  Widget _row(ColorScheme cs, String time, IconData icon, bool done,
      String layout) {
    final showLines = layout == 'full';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(time,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: cs.primary, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: 150,
                  decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4)),
                ),
                if (showLines) ...[
                  const SizedBox(height: 4),
                  Container(
                    height: 10,
                    width: 200,
                    decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.check_circle, color: cs.onSurface, size: 16),
        ],
      ),
    );
  }

  Widget _gapRow(ColorScheme cs, String layout) {
    if (layout == 'minimal') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 48),
          SizedBox(width: 32, child: Icon(Icons.timer_outlined, color: cs.onSurfaceVariant, size: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('30m free. Anything you\'…',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppPrefs().primaryColor,
      builder: (context, current, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in AppPrefs.palette)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _colorCircle(context, c, selected: c == current),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _colorCircle(BuildContext context, int colorValue,
      {required bool selected}) {
    final color = Color(colorValue);
    return InkWell(
      onTap: () => AppPrefs().setPrimaryColor(colorValue),
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
              color: color, width: selected ? 3 : 2),
        ),
        child: selected
            ? Center(
                child: Icon(Icons.check, color: color, size: 20),
              )
            : null,
      ),
    );
  }
}

class _LayoutToggle extends StatelessWidget {
  const _LayoutToggle();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ValueListenableBuilder<String>(
      valueListenable: AppPrefs().layoutMode,
      builder: (context, mode, _) {
        return SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'full', label: Text(l.layoutFull)),
            ButtonSegment(value: 'simplified', label: Text(l.layoutSimplified)),
            ButtonSegment(value: 'minimal', label: Text(l.layoutMinimal)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => AppPrefs().setLayoutMode(s.first),
        );
      },
    );
  }
}
