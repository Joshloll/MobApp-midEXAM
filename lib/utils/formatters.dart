import '../config/app_config.dart';

class Formatters {
  /// ₱1,234.50
  static String money(double value) =>
      currency(value, AppConfig.currencySymbol);

  /// Any currency with 2 decimals, e.g. currency(491.53, r'$') → $491.53
  static String currency(double value, String symbol) =>
      '$symbol${_grouped(value, 2)}';

  /// ₱12.3K / ₱1.2M for tight spaces; falls back to [money] below 10,000.
  static String compactMoney(double value) {
    final abs = value.abs();
    if (abs >= 1e6) {
      return '${AppConfig.currencySymbol}${_trim((value / 1e6).toStringAsFixed(1))}M';
    }
    if (abs >= 1e4) {
      return '${AppConfig.currencySymbol}${_trim((value / 1e3).toStringAsFixed(1))}K';
    }
    return money(value);
  }

  /// 12 / 8.5 / 9.25 without trailing zeros, grouped by thousands.
  static String quantity(double value) {
    final fixed = _grouped(value, 2);
    return fixed.contains('.') ? _trim(fixed) : fixed;
  }

  static String _grouped(double value, int decimals) {
    final negative = value < 0;
    final parts = value.abs().toStringAsFixed(decimals).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final result = parts.length > 1 ? '$whole.${parts[1]}' : whole;
    return negative ? '-$result' : result;
  }

  static String _trim(String s) {
    if (!s.contains('.')) return s;
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String date(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  /// Sep 26, 2026, 8:02 AM
  static String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  /// 8:02:15 PM (with seconds) or 8:02 PM
  static String time(DateTime d, {bool seconds = false}) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final second = seconds ? ':${d.second.toString().padLeft(2, '0')}' : '';
    return '$hour:$minute$second ${d.hour < 12 ? 'AM' : 'PM'}';
  }
}
