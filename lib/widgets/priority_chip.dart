import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';

import '../theme/app_theme.dart';

class PriorityChip extends StatelessWidget {
  final int priority;
  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = [AppPalette.secondary, AppPalette.primary, AppPalette.tertiary];
    final labels = [l.priorityLow, l.priorityMedium, l.priorityHigh];
    final i = priority.clamp(0, 2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors[i].withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labels[i],
        style: TextStyle(color: colors[i], fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
