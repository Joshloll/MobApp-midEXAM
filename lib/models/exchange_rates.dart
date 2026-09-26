/// Exchange rates returned by ExchangeRate-API.
///
/// Example of the real response (shortened):
/// {
///   "result": "success",
///   "time_last_update_unix": 1790380952,
///   "time_last_update_utc": "Sat, 26 Sep 2026 00:02:32 +0000",
///   "base_code": "PHP",
///   "rates": { "PHP": 1, "USD": 0.015998, "JPY": 2.522873, "SGD": 0.020444, ... }
/// }
class ExchangeRates {
  final String baseCode;
  final DateTime lastUpdated;
  final Map<String, double> rates;

  const ExchangeRates({
    required this.baseCode,
    required this.lastUpdated,
    required this.rates,
  });

  factory ExchangeRates.fromJson(Map<String, dynamic> json) {
    final baseCode = json['base_code'];
    final updatedUnix = json['time_last_update_unix'];
    final rawRates = json['rates'];

    if (baseCode is! String || updatedUnix is! num || rawRates is! Map) {
      throw const FormatException(
        'Missing base_code, time_last_update_unix or rates.',
      );
    }

    // Rates can arrive as int (e.g. "PHP": 1) or double (e.g. "USD": 0.015998),
    // so every number is converted with toDouble(). Non-numbers are skipped.
    final rates = <String, double>{};
    rawRates.forEach((code, value) {
      if (value is num) {
        rates[code.toString()] = value.toDouble();
      }
    });

    return ExchangeRates(
      baseCode: baseCode,
      // The API gives seconds since 1970 (UTC); convert to the phone's local time.
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        updatedUnix.toInt() * 1000,
        isUtc: true,
      ).toLocal(),
      rates: rates,
    );
  }

  /// Returns the rate for [currencyCode], or null if the API did not include it.
  double? rateFor(String currencyCode) => rates[currencyCode];
}
