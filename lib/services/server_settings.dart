import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Holds the API base URL in use, persisted across launches so the app can be
/// pointed at any server (emulator host, LAN IP, hosted VPS) without rebuilding.
class ServerSettings {
  static const String _prefsKey = 'api_base_url';

  static String _apiBaseUrl = AppConfig.defaultApiBaseUrl;

  static String get apiBaseUrl => _apiBaseUrl;

  static bool get isCustom => _apiBaseUrl != AppConfig.defaultApiBaseUrl;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _apiBaseUrl = normalize(saved);
      }
    } catch (_) {
      // Storage can be unavailable (private browsing, tests); keep the default.
    }
  }

  static Future<void> save(String url) async {
    _apiBaseUrl = normalize(url);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _apiBaseUrl);
    } catch (_) {}
  }

  static Future<void> reset() async {
    _apiBaseUrl = AppConfig.defaultApiBaseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  /// Trims whitespace and trailing slashes, adds http:// when no scheme is given,
  /// and strips a pasted `/dry_goods.php` so either form is accepted.
  static String normalize(String url) {
    var value = url.trim();
    if (value.isEmpty) return AppConfig.defaultApiBaseUrl;
    if (!value.contains('://')) value = 'http://$value';
    if (value.toLowerCase().endsWith('/dry_goods.php')) {
      value = value.substring(0, value.length - '/dry_goods.php'.length);
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static String? validate(String? url) {
    final value = normalize(url ?? '');
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid URL, e.g. http://192.168.1.10${AppConfig.apiPath}';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL must start with http:// or https://';
    }
    return null;
  }
}
