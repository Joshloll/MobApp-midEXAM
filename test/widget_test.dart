import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobapp_midexam/main.dart';
import 'package:mobapp_midexam/services/api_service.dart';
import 'package:mobapp_midexam/services/inventory_store.dart';
import 'package:mobapp_midexam/services/server_settings.dart';
import 'package:mobapp_midexam/utils/formatters.dart';

void main() {
  final mockClient = MockClient((request) async {
    return http.Response(
      jsonEncode({
        'success': true,
        'message': 'ok',
        'data': [
          {
            'id': 1,
            'product_name': 'White Sugar',
            'category': 'Sugar',
            'quantity': '5.00',
            'unit': 'kg',
            'price': '68.50',
            'supplier': 'City Grain Traders',
            'description': null,
            'created_at': '2026-09-01 10:00:00',
          },
          {
            'id': 2,
            'product_name': 'Premium Rice',
            'category': 'Rice',
            'quantity': '40.00',
            'unit': 'bag',
            'price': '1245.00',
            'supplier': null,
            'description': null,
            'created_at': '2026-09-02 10:00:00',
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  testWidgets('Dashboard and inventory render products from the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      DryGoodsApp(
        store: InventoryStore(api: ApiService(client: mockClient)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total products'), findsOneWidget);
    expect(find.text('White Sugar'), findsWidgets);

    await tester.tap(find.text('Inventory').last);
    await tester.pumpAndSettle();
    expect(find.text('Premium Rice'), findsWidgets);
    expect(find.text('₱1,245.00'), findsWidgets);
  });

  test('Server URL normalisation', () {
    expect(
      ServerSettings.normalize(' 192.168.1.5/MobApp-midEXAM/backend/api/ '),
      'http://192.168.1.5/MobApp-midEXAM/backend/api',
    );
    expect(
      ServerSettings.normalize('http://host/api/dry_goods.php'),
      'http://host/api',
    );
    expect(ServerSettings.validate('http://'), isNotNull);
    expect(ServerSettings.validate('http://10.0.2.2/api'), isNull);
  });

  test('Formatters', () {
    expect(Formatters.money(1234567.5), '₱1,234,567.50');
    expect(Formatters.quantity(8.5), '8.5');
    expect(Formatters.quantity(12), '12');
    expect(Formatters.compactMoney(25300), '₱25.3K');
  });
}
