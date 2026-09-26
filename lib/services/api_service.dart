import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/dry_good.dart';
import 'server_settings.dart';

class ApiException implements Exception {
  final String message;

  /// True when the server could not be reached at all (as opposed to the
  /// server answering with an error), so the UI can offer the settings screen.
  final bool isConnectionError;

  const ApiException(this.message, {this.isConnectionError = false});

  @override
  String toString() => message;
}

class ApiService {
  final http.Client client;

  /// Overrides [ServerSettings.apiBaseUrl]; used to test a URL before saving it.
  final String? baseUrl;

  ApiService({http.Client? client, this.baseUrl})
    : client = client ?? http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  String get _base =>
      ServerSettings.normalize(baseUrl ?? ServerSettings.apiBaseUrl);

  Uri _apiUri([Map<String, String>? query]) {
    final uri = Uri.parse('$_base/dry_goods.php');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'The server at $_base did not respond in time.',
        isConnectionError: true,
      );
    } on http.ClientException {
      throw ApiException(
        'Cannot reach the server at $_base.',
        isConnectionError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      // dart:io SocketException etc. (not importable on web).
      throw ApiException(
        'Cannot reach the server at $_base.',
        isConnectionError: true,
      );
    }
  }

  Future<List<DryGood>> fetchProducts() async {
    final response = await _send(
      () => client.get(_apiUri(), headers: {'Accept': 'application/json'}),
    );

    final decoded = _decodeJson(response, allowEmptyList: true);
    final data = decoded['data'];

    if (data is! List) {
      throw const ApiException(
        'The API response was not in the expected list format.',
      );
    }

    return data
        .map((item) => DryGood.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<DryGood> fetchProductById(int id) async {
    final response = await _send(
      () => client.get(
        _apiUri({'id': id.toString()}),
        headers: {'Accept': 'application/json'},
      ),
    );

    final decoded = _decodeJson(response);
    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'The product data was missing from the API response.',
      );
    }

    return DryGood.fromJson(data);
  }

  Future<DryGood> createProduct(DryGood product) async {
    final response = await _send(
      () => client.post(
        _apiUri(),
        headers: _jsonHeaders,
        body: jsonEncode(product.toJson()),
      ),
    );

    final decoded = _decodeJson(response, expectedStatusCode: 201);
    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('The new product was not returned by the API.');
    }

    return DryGood.fromJson(data);
  }

  Future<DryGood> updateProduct(DryGood product) async {
    final response = await _send(
      () => client.put(
        _apiUri({'id': (product.id ?? 0).toString()}),
        headers: _jsonHeaders,
        body: jsonEncode(product.toJson()),
      ),
    );

    final decoded = _decodeJson(response, expectedStatusCode: 200);
    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'The updated product was not returned by the API.',
      );
    }

    return DryGood.fromJson(data);
  }

  Future<void> deleteProduct(int id) async {
    final response = await _send(
      () => client.delete(
        _apiUri({'id': id.toString()}),
        headers: {'Accept': 'application/json'},
      ),
    );

    _decodeJson(response, expectedStatusCode: 200);
  }

  /// Checks that [baseUrl] (or the saved URL) serves the dry goods API.
  /// Returns the number of products on success.
  Future<int> testConnection() async {
    final products = await fetchProducts();
    return products.length;
  }

  Map<String, dynamic> _decodeJson(
    http.Response response, {
    int expectedStatusCode = 200,
    bool allowEmptyList = false,
  }) {
    if (response.statusCode != expectedStatusCode) {
      String? serverMessage;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final errors = decoded['errors'];
          if (errors is Map && errors.isNotEmpty) {
            serverMessage = errors.values.first?.toString();
          }
          serverMessage ??= decoded['message']?.toString();
        }
      } catch (_) {
        // Not JSON (e.g. an Apache 404 page); fall back to a status message.
      }

      if (serverMessage != null) throw ApiException(serverMessage);
      if (response.statusCode == 404) {
        throw ApiException(
          'The API was not found at $_base. Check the server URL in Settings.',
        );
      }
      throw ApiException(
        'Request failed with status code ${response.statusCode}.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('The API did not return a valid JSON object.');
      }

      final success = decoded['success'];
      if (success == false) {
        final message = decoded['message'] ?? 'The request failed.';
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.firstOrNull;
          throw ApiException(firstError?.toString() ?? message.toString());
        }
        throw ApiException(message.toString());
      }

      if (allowEmptyList && decoded['data'] == null) {
        return {'data': <dynamic>[]};
      }

      return decoded;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        'The server at $_base did not return valid API data. Check the server URL in Settings.',
      );
    }
  }
}
