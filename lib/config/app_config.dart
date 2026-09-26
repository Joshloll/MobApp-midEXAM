import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Dry Goods Inventory';

  /// Folder under the web server root where this project is served
  /// (e.g. C:/xampp/htdocs/MobApp-midEXAM → /MobApp-midEXAM/backend/api).
  static const String apiPath = '/MobApp-midEXAM/backend/api';

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Default API location for the current platform. Users can override it at
  /// runtime from the Server Settings screen, or at build time with
  /// `--dart-define=API_BASE_URL=...`.
  static String get defaultApiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    // 10.0.2.2 is the Android emulator's alias for the host machine; it is
    // unreachable from web/desktop builds, which must use localhost instead.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2$apiPath';
    }
    if (kIsWeb) {
      // When the web build is served by the same Apache as the API (LAN IP or a
      // DuckDNS domain, http or https), call the API on that same origin. This
      // also avoids browsers blocking http calls from an https page.
      final base = Uri.base;
      final isDefaultPort =
          (base.scheme == 'http' && base.port == 80) ||
          (base.scheme == 'https' && base.port == 443);
      if (base.host.isNotEmpty && isDefaultPort) {
        return '${base.origin}$apiPath';
      }
    }
    return 'http://localhost$apiPath';
  }

  /// Third-party API: ExchangeRate-API (open access, no API key needed).
  /// Returns today's exchange rates with the Philippine Peso as the base.
  static const String exchangeRateApiUrl =
      'https://open.er-api.com/v6/latest/PHP';

  static const Duration requestTimeout = Duration(seconds: 10);
  static const int lowStockThreshold = 10;
  static const String currencySymbol = '₱';
}
