import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/event_edit_screen.dart';
import 'screens/goal_detail_screen.dart';
import 'screens/habit_detail_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/task_edit_screen.dart';
import 'services/ai_chat_service.dart';
import 'services/ai_config.dart';
import 'services/app_prefs.dart';
import 'services/locale_service.dart';
import 'services/pending_plan_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  await LocaleService().init();
  await AIConfig().init();
  await AIChatService().init();
  await AppPrefs().init();
  await PendingPlanService().init();
  await WidgetService().init();
  runApp(const OnePlannerApp());
}

class OnePlannerApp extends StatefulWidget {
  const OnePlannerApp({super.key});

  @override
  State<OnePlannerApp> createState() => _OnePlannerAppState();
}

class _OnePlannerAppState extends State<OnePlannerApp> with WidgetsBindingObserver {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboarding();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().init();
      NotificationService().onTap = _routeFromPayload;
      await NotificationService().scheduleGoalPulses();
      AppPrefs().goalPulsesEnabled.addListener(
          () => NotificationService().scheduleGoalPulses());
      // Ensure the home-screen widget has data right now.
      await WidgetService().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetService().refresh();
    }
  }

  Future<void> _checkOnboarding() async {
    final show = await OnboardingScreen.shouldShow();
    if (mounted) setState(() => _showOnboarding = show);
  }

  void _routeFromPayload(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    final id = payload['id'] as String?;
    if (type == null || id == null) return;
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    switch (type) {
      case 'task':
        final t = StorageService().tasks.get(id);
        if (t != null) {
          nav.push(MaterialPageRoute(
              builder: (_) => TaskEditScreen(existing: t)));
        }
        break;
      case 'event':
        final e = StorageService().events.get(id);
        if (e != null) {
          nav.push(MaterialPageRoute(
              builder: (_) => EventEditScreen(existing: e)));
        }
        break;
      case 'habit':
        final h = StorageService().habits.get(id);
        if (h != null) {
          nav.push(MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habit: h)));
        }
        break;
      case 'goal':
        final g = StorageService().goals.get(id);
        if (g != null) {
          nav.push(MaterialPageRoute(
              builder: (_) => GoalDetailScreen(goal: g)));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService().notifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<int>(
          valueListenable: AppPrefs().primaryColor,
          builder: (context, primaryColor, _) {
            return MaterialApp(
              navigatorKey: rootNavigatorKey,
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
              theme: AppTheme.light(locale, primaryColor),
              darkTheme: AppTheme.dark(locale, primaryColor),
              themeMode: ThemeMode.system,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: _showOnboarding == null
                  ? const Scaffold(
                      body: Center(child: CircularProgressIndicator()))
                  : (_showOnboarding!
                      ? OnboardingScreen(
                          onDone: () =>
                              setState(() => _showOnboarding = false))
                      : const MainShell()),
            );
          },
        );
      },
    );
  }
}
