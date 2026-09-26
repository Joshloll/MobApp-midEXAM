import 'package:flutter/material.dart';

import '../models/exchange_rates.dart';
import '../services/external_api_service.dart';
import '../utils/formatters.dart';

/// Dashboard card that converts the total inventory value (₱) into other
/// currencies using live rates from ExchangeRate-API.
///
/// It loads its own data with setState, independently of the product list,
/// so if this API fails the rest of the Dashboard still works.
class InventoryValueAbroadCard extends StatefulWidget {
  const InventoryValueAbroadCard({
    super.key,
    required this.totalValuePhp,
    this.service,
  });

  /// Total inventory value in Philippine Pesos (sum of quantity × price).
  final double totalValuePhp;

  /// Optional, so tests can pass a fake HTTP client.
  final ExternalApiService? service;

  @override
  State<InventoryValueAbroadCard> createState() =>
      _InventoryValueAbroadCardState();
}

class _InventoryValueAbroadCardState extends State<InventoryValueAbroadCard> {
  /// Currencies shown on the card: code → (symbol, name).
  static const _currencies = [
    (code: 'USD', symbol: r'$', name: 'US Dollar'),
    (code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    (code: 'SGD', symbol: r'S$', name: 'Singapore Dollar'),
  ];

  late final ExternalApiService _service =
      widget.service ?? ExternalApiService();

  bool _isLoading = false;
  String? _errorMessage;
  ExchangeRates? _rates;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rates = await _service.fetchRates();
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _lastChecked = DateTime.now();
      });
    } on ExternalApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Something went wrong while loading exchange rates.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + Refresh button
            Row(
              children: [
                Icon(
                  Icons.currency_exchange_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory Value Abroad',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        // Attribution required by ExchangeRate-API's free-tier terms.
                        'Rates By Exchange Rate API · exchangerate-api.com',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _isLoading ? null : _loadRates,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBody(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final muted = theme.colorScheme.onSurfaceVariant;

    // Loading state: small spinner inside the card only.
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    // Error state: friendly message + Retry.
    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_errorMessage!, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadRates,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    final rates = _rates;
    if (rates == null) return const SizedBox.shrink();

    // Data state
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total inventory value',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        Text(
          Formatters.money(widget.totalValuePhp),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        for (final currency in _currencies)
          _buildCurrencyRow(theme, rates, currency),
        const Divider(height: 24),
        Text(
          'Rates updated: ${Formatters.dateTime(rates.lastUpdated)}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_lastChecked != null)
          Text(
            'Last checked: ${Formatters.time(_lastChecked!, seconds: true)}',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
      ],
    );
  }

  Widget _buildCurrencyRow(
    ThemeData theme,
    ExchangeRates rates,
    ({String code, String symbol, String name}) currency,
  ) {
    final muted = theme.colorScheme.onSurfaceVariant;
    final rate = rates.rateFor(currency.code);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currency.code,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currency.name, style: theme.textTheme.bodyMedium),
                Text(
                  // "No data" state for this line: the API did not send this currency.
                  rate == null
                      ? 'Rate unavailable'
                      : '1 ${rates.baseCode} = $rate ${currency.code}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          Text(
            rate == null
                ? 'Rate unavailable'
                : Formatters.currency(
                    widget.totalValuePhp * rate,
                    currency.symbol,
                  ),
            style: rate == null
                ? theme.textTheme.bodyMedium?.copyWith(color: muted)
                : theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
