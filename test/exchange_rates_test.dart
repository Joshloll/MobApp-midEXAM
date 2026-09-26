import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobapp_midexam/models/exchange_rates.dart';
import 'package:mobapp_midexam/services/external_api_service.dart';
import 'package:mobapp_midexam/widgets/inventory_value_abroad_card.dart';

// Shape copied from the real https://open.er-api.com/v6/latest/PHP response.
Map<String, dynamic> sample({bool includeSgd = true}) => {
  'result': 'success',
  'time_last_update_unix': 1790380952,
  'time_last_update_utc': 'Sat, 26 Sep 2026 00:02:32 +0000',
  'base_code': 'PHP',
  'rates': {'PHP': 1, 'USD': 0.016, 'JPY': 2.5, if (includeSgd) 'SGD': 0.02},
};

Widget card(http.Client client) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: InventoryValueAbroadCard(
        totalValuePhp: 1000,
        service: ExternalApiService(client: client),
      ),
    ),
  ),
);

void main() {
  test('fromJson accepts int and double rates', () {
    final rates = ExchangeRates.fromJson(sample());
    expect(rates.baseCode, 'PHP');
    expect(rates.rateFor('PHP'), 1.0);
    expect(rates.rateFor('USD'), 0.016);
    expect(rates.rateFor('XYZ'), isNull);
    expect(rates.lastUpdated.toUtc(), DateTime.utc(2026, 9, 26, 0, 2, 32));
  });

  test('result other than success throws', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'result': 'error', 'error-type': 'unsupported-code'}),
        200,
      ),
    );
    expect(
      ExternalApiService(client: client).fetchRates(),
      throwsA(isA<ExternalApiException>()),
    );
  });

  testWidgets(
    'shows converted values and "Rate unavailable" for a missing currency',
    (tester) async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode(sample(includeSgd: false)), 200),
      );
      await tester.pumpWidget(card(client));
      await tester.pumpAndSettle();

      expect(find.text('₱1,000.00'), findsOneWidget);
      expect(find.text(r'$16.00'), findsOneWidget);
      expect(find.text('¥2,500.00'), findsOneWidget);
      expect(find.text('Rate unavailable'), findsNWidgets(2));
      expect(find.textContaining('Rates updated:'), findsOneWidget);
    },
  );

  testWidgets('no internet shows error, Retry recovers', (tester) async {
    var online = false;
    final client = MockClient((request) async {
      if (!online) throw http.ClientException('offline', request.url);
      return http.Response(jsonEncode(sample()), 200);
    });
    await tester.pumpWidget(card(client));
    await tester.pumpAndSettle();
    expect(find.textContaining('No internet connection'), findsOneWidget);

    online = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text(r'S$20.00'), findsOneWidget);
  });
}
