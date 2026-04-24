import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';

import '../services/ai_config.dart';
import '../services/ai_service.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;
  bool _testing = false;
  bool? _lastTestOk;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _baseUrl = TextEditingController(text: AIConfig().baseUrl.value);
    _model = TextEditingController(text: AIConfig().model.value);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await AIConfig().setBaseUrl(_baseUrl.text);
    await AIConfig().setModel(_model.text);
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context)!;
    await _save();
    setState(() {
      _testing = true;
      _lastTestOk = null;
      _lastError = null;
    });
    final result = await AIService().testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _lastTestOk = result.ok;
      _lastError = result.error;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(result.ok ? l.aiConnectionOk : l.aiConnectionFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.aiAssistant)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AIConfig().enabled,
            builder: (context, enabled, _) => SwitchListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: cs.surfaceContainerHighest,
              title: Text(l.aiEnabled),
              value: enabled,
              onChanged: (v) => AIConfig().setEnabled(v),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrl,
            decoration: InputDecoration(labelText: l.aiBaseUrl),
            onChanged: (v) => AIConfig().setBaseUrl(v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            decoration: InputDecoration(labelText: l.aiModel),
            onChanged: (v) => AIConfig().setModel(v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _lastTestOk == null
                          ? Icons.wifi_tethering
                          : _lastTestOk!
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                    ),
              label: Text(l.aiTestConnection),
              onPressed: _testing ? null : _test,
            ),
          ),
          const SizedBox(height: 12),
          if (_lastTestOk == false && _lastError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _lastError!,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.error,
                    fontFamily: 'monospace'),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            l.aiUsageHint,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
