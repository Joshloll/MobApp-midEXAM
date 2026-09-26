import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/inventory_store.dart';
import '../services/server_settings.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  /// Opens the screen and reloads the inventory if the server URL changed.
  static Future<void> open(BuildContext context) async {
    final store = InventoryScope.read(context);
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    if (changed == true) await store.load();
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _TestState { idle, running, success, failure }

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController = TextEditingController(
    text: ServerSettings.apiBaseUrl,
  );

  _TestState _testState = _TestState.idle;
  String? _testMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _testState = _TestState.running;
      _testMessage = null;
    });

    try {
      final count = await ApiService(
        baseUrl: _urlController.text,
      ).testConnection();
      if (!mounted) return;
      setState(() {
        _testState = _TestState.success;
        _testMessage =
            'Connected. The API returned $count product${count == 1 ? '' : 's'}.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _testState = _TestState.failure;
        _testMessage = e.message;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ServerSettings.save(_urlController.text);
    if (!mounted) return;
    showAppSnackBar(context, 'Server URL saved.');
    Navigator.pop(context, true);
  }

  Future<void> _reset() async {
    await ServerSettings.reset();
    if (!mounted) return;
    setState(() {
      _urlController.text = ServerSettings.apiBaseUrl;
      _testState = _TestState.idle;
      _testMessage = null;
    });
  }

  void _usePreset(String url) {
    setState(() {
      _urlController.text = url;
      _testState = _TestState.idle;
      _testMessage = null;
    });
  }

  String get _platformLabel {
    if (kIsWeb) return 'Web browser';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Server settings')),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 680,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Point the app at the PHP API. The URL is saved on this device, so the same build works on '
                  'an emulator, a phone on your Wi-Fi, or a hosted server.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: ServerSettings.validate,
                  onChanged: (_) =>
                      setState(() => _testState = _TestState.idle),
                  decoration: const InputDecoration(
                    labelText: 'API base URL',
                    hintText: 'http://192.168.1.10${AppConfig.apiPath}',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.computer_rounded, size: 18),
                      label: const Text('This computer'),
                      onPressed: () =>
                          _usePreset('http://localhost${AppConfig.apiPath}'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.phone_android_rounded, size: 18),
                      label: const Text('Android emulator'),
                      onPressed: () =>
                          _usePreset('http://10.0.2.2${AppConfig.apiPath}'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi_rounded, size: 18),
                      label: const Text('Device on Wi-Fi'),
                      onPressed: () =>
                          _usePreset('http://192.168.1.10${AppConfig.apiPath}'),
                    ),
                  ],
                ),
                if (_testMessage != null) ...[
                  const SizedBox(height: 20),
                  _TestResult(
                    success: _testState == _TestState.success,
                    message: _testMessage!,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testState == _TestState.running
                            ? null
                            : _testConnection,
                        icon: _testState == _TestState.running
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.network_check_rounded),
                        label: const Text('Test connection'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  child: TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset to default'),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Which URL should I use?',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        _Tip(
                          icon: Icons.computer_rounded,
                          text:
                              'Web or desktop on the XAMPP computer: localhost',
                        ),
                        _Tip(
                          icon: Icons.phone_android_rounded,
                          text:
                              'Android emulator: 10.0.2.2 (the emulator’s alias for your computer)',
                        ),
                        _Tip(
                          icon: Icons.wifi_rounded,
                          text:
                              'Real phone: your computer’s Wi-Fi IP (run ipconfig, look for IPv4 Address). '
                              'Both devices must be on the same network and Windows Firewall must allow Apache.',
                        ),
                        const Divider(height: 28),
                        _KeyValue(label: 'Platform', value: _platformLabel),
                        _KeyValue(
                          label: 'Default URL',
                          value: AppConfig.defaultApiBaseUrl,
                        ),
                        _KeyValue(
                          label: 'In use',
                          value: ServerSettings.apiBaseUrl,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TestResult extends StatelessWidget {
  const _TestResult({required this.success, required this.message});

  final bool success;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = success
        ? const Color(0xFF15803D)
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
