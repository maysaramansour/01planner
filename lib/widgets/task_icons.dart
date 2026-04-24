import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';

class TaskIcons {
  static const Map<String, IconData> map = {
    'work': Icons.work_outline,
    'gym': Icons.fitness_center_outlined,
    'call': Icons.call_outlined,
    'home': Icons.home_outlined,
    'shop': Icons.shopping_bag_outlined,
    'study': Icons.menu_book_outlined,
    'food': Icons.restaurant_outlined,
    'travel': Icons.flight_takeoff_outlined,
    'health': Icons.favorite_outline,
    'meet': Icons.groups_outlined,
    'read': Icons.auto_stories_outlined,
    'idea': Icons.lightbulb_outline,
  };

  static IconData iconFor(String? key) =>
      map[key ?? ''] ?? Icons.check_circle_outline;

  static String labelFor(AppLocalizations l, String key) {
    switch (key) {
      case 'work':
        return l.iconWork;
      case 'gym':
        return l.iconGym;
      case 'call':
        return l.iconCall;
      case 'home':
        return l.iconHome;
      case 'shop':
        return l.iconShop;
      case 'study':
        return l.iconStudy;
      case 'food':
        return l.iconFood;
      case 'travel':
        return l.iconTravel;
      case 'health':
        return l.iconHealth;
      case 'meet':
        return l.iconMeet;
      case 'read':
        return l.iconRead;
      case 'idea':
        return l.iconIdea;
      default:
        return key;
    }
  }
}
