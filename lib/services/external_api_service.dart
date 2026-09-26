import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/exchange_rates.dart';

class ExternalApiException implements Exception {
  final String message;

  const ExternalApiException(this.message);

  @override
  String toString() => message;
}

/// Talks to the third-party ExchangeRate-API. Kept separate from [ApiService]
/// (our own PHP backend) so a failure here never affects the CRUD features.
class ExternalApiService {
  final http.Client client;

  ExternalApiService({http.Client? client}) : client = client ?? http.Client();

  /// GET https://open.er-api.com/v6/latest/PHP and parse it into [ExchangeRates].
  Future<ExchangeRates> fetchRates() async {
    final http.Response response;

    // 1. Send the HTTP GET request (10-second limit).
    try {
      response = await client
          .get(
            Uri.parse(AppConfig.exchangeRateApiUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ExternalApiException(
        'The exchange rate service took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ExternalApiException(
        'No internet connection. Check your connection and try again.',
      );
    }

    // 2. Check the HTTP status code.
    if (response.statusCode != 200) {
      throw ExternalApiException(
        'The exchange rate service returned an error (HTTP ${response.statusCode}).',
      );
    }

    // 3. Decode the JSON and check the API's own "result" field.
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Not a JSON object.');
      }
      json = decoded;
    } on FormatException {
      throw const ExternalApiException(
        'Unexpected response from the exchange rate service.',
      );
    }

    if (json['result'] != 'success') {
      final reason = json['error-type'] ?? 'unknown error';
      throw ExternalApiException(
        'The exchange rate service reported an error: $reason.',
      );
    }

    // 4. Turn the JSON into our model.
    try {
      return ExchangeRates.fromJson(json);
    } on FormatException {
      throw const ExternalApiException(
        'Unexpected response from the exchange rate service.',
      );
    }
  }
}
