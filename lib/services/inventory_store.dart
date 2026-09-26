import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../models/dry_good.dart';
import 'api_service.dart';

/// Single source of truth for the product list, shared by the dashboard and
/// inventory screens so a change made on one is reflected on the other.
class InventoryStore extends ChangeNotifier {
  InventoryStore({ApiService? api}) : api = api ?? ApiService();

  final ApiService api;

  List<DryGood> _products = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  ApiException? _error;

  List<DryGood> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  ApiException? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await api.fetchProducts();
      _hasLoaded = true;
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException('Unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadIfNeeded() async {
    if (!_hasLoaded && !_isLoading) await load();
  }

  Future<DryGood> create(DryGood product) async {
    final created = await api.createProduct(product);
    _products = [created, ..._products];
    notifyListeners();
    return created;
  }

  Future<DryGood> update(DryGood product) async {
    final updated = await api.updateProduct(product);
    _products = [for (final p in _products) p.id == updated.id ? updated : p];
    notifyListeners();
    return updated;
  }

  Future<void> delete(int id) async {
    await api.deleteProduct(id);
    _products = _products.where((p) => p.id != id).toList();
    notifyListeners();
  }

  DryGood? byId(int? id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<String> get categories {
    final set =
        _products
            .map((p) => p.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return set;
  }

  List<String> get units {
    final set =
        _products.map((p) => p.unit).where((u) => u.isNotEmpty).toSet().toList()
          ..sort();
    return set;
  }

  double get totalValue =>
      _products.fold(0, (sum, p) => sum + p.quantity * p.price);

  double get totalUnits => _products.fold(0, (sum, p) => sum + p.quantity);

  List<DryGood> get lowStock =>
      _products.where((p) => p.quantity <= AppConfig.lowStockThreshold).toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));

  /// Category → total stock value, highest first.
  List<MapEntry<String, double>> get valueByCategory {
    final map = <String, double>{};
    for (final p in _products) {
      map[p.category] = (map[p.category] ?? 0) + p.quantity * p.price;
    }
    return map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }
}

/// Makes the [InventoryStore] available to the widget tree and rebuilds
/// dependents when it changes.
class InventoryScope extends InheritedNotifier<InventoryStore> {
  const InventoryScope({
    super.key,
    required InventoryStore store,
    required super.child,
  }) : super(notifier: store);

  static InventoryStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InventoryScope>()!.notifier!;

  /// Access without subscribing to rebuilds (for callbacks).
  static InventoryStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<InventoryScope>()!.notifier!;
}
