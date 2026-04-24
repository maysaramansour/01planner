import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/locale_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  static const _kDoneFlag = 'onboarding.completed';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kDoneFlag) ?? false);
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDoneFlag, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pages = <_OnbPage>[
      _OnbPage(
        emoji: '👋',
        titleColor: cs.primary,
        title: l.onbWelcomeTitle,
        body: l.onbWelcomeBody,
      ),
      _OnbPage(
        emoji: '🗓️',
        titleColor: cs.primary,
        title: l.onbTimelineTitle,
        body: l.onbTimelineBody,
      ),
      _OnbPage(
        emoji: '🎯',
        titleColor: cs.primary,
        title: l.onbGoalsTitle,
        body: l.onbGoalsBody,
      ),
      _OnbPage(
        emoji: '✨',
        titleColor: cs.primary,
        title: l.onbAiTitle,
        body: l.onbAiBody,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip + language
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ValueListenableBuilder<Locale>(
                    valueListenable: LocaleService().notifier,
                    builder: (c, cur, _) => DropdownButton<String>(
                      value: cur.languageCode,
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
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(l.onbSkip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => pages[i].build(context),
              ),
            ),
            // Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    Container(
                      width: i == _page ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            i == _page ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_page < pages.length - 1) {
                      _ctl.nextPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut);
                    } else {
                      _finish();
                    }
                  },
                  child: Text(_page < pages.length - 1 ? l.onbNext : l.onbGetStarted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (mounted) widget.onDone();
  }
}

class _OnbPage {
  final String emoji;
  final String title;
  final String body;
  final Color titleColor;
  _OnbPage({
    required this.emoji,
    required this.title,
    required this.body,
    required this.titleColor,
  });

  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 64))),
          ),
          const SizedBox(height: 32),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: titleColor)),
          const SizedBox(height: 16),
          Text(body,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
