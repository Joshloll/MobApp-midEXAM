import 'package:flutter/material.dart';

import '../models/dry_good.dart';
import '../services/inventory_store.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'settings_screen.dart';

enum _SortOption {
  newest('Newest first'),
  nameAsc('Name (A–Z)'),
  quantityAsc('Lowest stock'),
  priceDesc('Highest price'),
  valueDesc('Highest stock value');

  const _SortOption(this.label);
  final String label;
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();

  String _searchText = '';
  String? _selectedCategory;
  bool _lowStockOnly = false;
  _SortOption _sort = _SortOption.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DryGood> _visibleProducts(InventoryStore store) {
    final query = _searchText.trim().toLowerCase();
    final result = store.products.where((p) {
      final matchesSearch =
          query.isEmpty ||
          p.productName.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.unit.toLowerCase().contains(query) ||
          (p.supplier?.toLowerCase().contains(query) ?? false);
      final matchesCategory =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchesStock =
          !_lowStockOnly || StockStatus.of(p) != StockStatus.inStock;
      return matchesSearch && matchesCategory && matchesStock;
    }).toList();

    switch (_sort) {
      case _SortOption.newest:
        break; // API already returns newest first.
      case _SortOption.nameAsc:
        result.sort(
          (a, b) => a.productName.toLowerCase().compareTo(
            b.productName.toLowerCase(),
          ),
        );
      case _SortOption.quantityAsc:
        result.sort((a, b) => a.quantity.compareTo(b.quantity));
      case _SortOption.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case _SortOption.valueDesc:
        result.sort(
          (a, b) => (b.price * b.quantity).compareTo(a.price * a.quantity),
        );
    }
    return result;
  }

  bool get _hasFilters =>
      _searchText.isNotEmpty || _selectedCategory != null || _lowStockOnly;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedCategory = null;
      _lowStockOnly = false;
    });
  }

  void _openProduct(DryGood product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  Future<void> _addProduct() async {
    final created = await Navigator.push<DryGood>(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (created != null && mounted) {
      showAppSnackBar(context, '“${created.productName}” added to inventory.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = InventoryScope.of(context);
    final theme = Theme.of(context);

    // Drop a category filter that no longer exists (e.g. after a delete).
    if (_selectedCategory != null &&
        !store.categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    final visible = _visibleProducts(store);

    Widget body;
    if (!store.hasLoaded && store.error != null) {
      body = StateMessage.error(context, store.error!, store.load);
    } else if (!store.hasLoaded) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Column(
        children: [
          ContentWidth(child: _buildFilters(context, store)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: store.load,
              child: visible.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 40),
                        StateMessage(
                          icon: store.products.isEmpty
                              ? Icons.inventory_2_outlined
                              : Icons.search_off_rounded,
                          title: store.products.isEmpty
                              ? 'No products yet'
                              : 'No matching products',
                          message: store.products.isEmpty
                              ? 'Add your first dry goods item to start tracking stock.'
                              : 'Try a different search term or clear the filters.',
                          actions: [
                            if (store.products.isEmpty)
                              FilledButton.icon(
                                onPressed: _addProduct,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add product'),
                              )
                            else
                              OutlinedButton(
                                onPressed: _clearFilters,
                                child: const Text('Clear filters'),
                              ),
                          ],
                        ),
                      ],
                    )
                  : _buildList(visible),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventory'),
            if (store.hasLoaded)
              Text(
                '${store.products.length} products · ${Formatters.money(store.totalValue)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: store.isLoading ? null : store.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Server settings',
            onPressed: () => SettingsScreen.open(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
        bottom: store.isLoading && store.hasLoaded
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: body,
      floatingActionButton: store.hasLoaded
          ? FloatingActionButton.extended(
              onPressed: _addProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            )
          : null,
    );
  }

  Widget _buildFilters(BuildContext context, InventoryStore store) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchText = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search name, category, supplier…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchText.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchText = '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_SortOption>(
                tooltip: 'Sort',
                initialValue: _sort,
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (_) => [
                  for (final option in _SortOption.values)
                    CheckedPopupMenuItem(
                      value: option,
                      checked: option == _sort,
                      child: Text(option.label),
                    ),
                ],
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: const Icon(Icons.sort_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  avatar: _lowStockOnly
                      ? null
                      : const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text('Low stock'),
                  selected: _lowStockOnly,
                  onSelected: (value) => setState(() => _lowStockOnly = value),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 24,
                  child: VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                for (final category in store.categories) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) => setState(
                      () => _selectedCategory = selected ? category : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_hasFilters)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text(
                    '${_visibleProducts(store).length} of ${store.products.length} shown',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<DryGood> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxWidth = 1100.0;
        final contentWidth = constraints.maxWidth.clamp(0.0, maxWidth);
        final sidePadding = 16 + (constraints.maxWidth - contentWidth) / 2;
        final columns = contentWidth >= 720 ? 2 : 1;
        final padding = EdgeInsets.fromLTRB(sidePadding, 4, sidePadding, 96);

        if (columns == 1) {
          return ListView.separated(
            padding: padding,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => ProductCard(
              product: products[index],
              onTap: () => _openProduct(products[index]),
            ),
          );
        }

        return GridView.builder(
          padding: padding,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 104,
          ),
          itemBuilder: (context, index) => ProductCard(
            product: products[index],
            onTap: () => _openProduct(products[index]),
          ),
        );
      },
    );
  }
}
