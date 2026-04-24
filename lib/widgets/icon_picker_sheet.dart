import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';

import '../services/ai_service.dart';
import 'task_icons.dart';

class IconColorPick {
  final String iconKey;
  final int colorValue;
  const IconColorPick(this.iconKey, this.colorValue);
}

Future<IconColorPick?> showIconPickerSheet(
  BuildContext context, {
  String? initialIconKey,
  int? initialColorValue,
}) {
  return showModalBottomSheet<IconColorPick>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _IconPickerSheet(
      initialIconKey: initialIconKey ?? 'work',
      initialColorValue: initialColorValue ?? kPaletteColors.first,
    ),
  );
}

class _IconPickerSheet extends StatefulWidget {
  final String initialIconKey;
  final int initialColorValue;
  const _IconPickerSheet({
    required this.initialIconKey,
    required this.initialColorValue,
  });

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  late String _iconKey = widget.initialIconKey;
  late int _colorValue = widget.initialColorValue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.icon,
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskIcons.map.entries.map((e) {
                final selected = e.key == _iconKey;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _iconKey = e.key),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? Color(_colorValue).withValues(alpha: 0.25)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Color(_colorValue) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(e.value, color: cs.onSurface),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(l.color,
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kPaletteColors.map((c) {
                final selected = c == _colorValue;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _colorValue = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? cs.onSurface : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  IconColorPick(_iconKey, _colorValue),
                ),
                child: Text(l.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
