import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/dry_good.dart';
import '../services/inventory_store.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/inventory_value_abroad_card.dart';
import 'inventory_screen.dart';
import 'product_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _railBreakpoint = 840;

  int _currentIndex = 0;

  static const _destinations = [
    (
      icon: Icons.space_dashboard_outlined,
      selected: Icons.space_dashboard_rounded,
      label: 'Dashboard',
    ),
    (
      icon: Icons.inventory_2_outlined,
      selected: Icons.inventory_2_rounded,
      label: 'Inventory',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) InventoryScope.read(context).loadIfNeeded();
    });
  }

  void _select(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _currentIndex,
      children: [
        DashboardView(onOpenInventory: () => _select(1)),
        const InventoryScreen(),
      ],
    );

    final isWide = MediaQuery.sizeOf(context).width >= _railBreakpoint;
    if (!isWide) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selected),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 1100,
            selectedIndex: _currentIndex,
            onDestinationSelected: _select,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Server settings',
                    onPressed: () => SettingsScreen.open(context),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, this.onOpenInventory});

  final VoidCallback? onOpenInventory;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Future<void> _refresh() async {
    await InventoryScope.read(context).load();
  }

  void _openProduct(DryGood product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = InventoryScope.of(context);

    Widget body;
    if (!store.hasLoaded && store.error != null) {
      body = StateMessage.error(context, store.error!, _refresh);
    } else if (!store.hasLoaded) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [ContentWidth(child: _buildContent(context, store))],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (store.isLoading && store.hasLoaded)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            tooltip: 'Server settings',
            onPressed: () => SettingsScreen.open(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
    );
  }

  Widget _buildContent(BuildContext context, InventoryStore store) {
    final theme = Theme.of(context);
    final lowStock = store.lowStock;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final twoColumn = width >= 760;

        final overview = _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Stock value by category',
                subtitle:
                    '${store.categories.length} categories · ${Formatters.quantity(store.totalUnits)} units on hand',
              ),
              _CategoryBreakdown(
                entries: store.valueByCategory,
                total: store.totalValue,
              ),
            ],
          ),
        );

        final restock = _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Needs restocking',
                subtitle: 'At or below ${AppConfig.lowStockThreshold} units',
                trailing: widget.onOpenInventory == null
                    ? null
                    : TextButton(
                        onPressed: widget.onOpenInventory,
                        child: const Text('View all'),
                      ),
              ),
              if (lowStock.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('All products are well stocked.'),
                      ),
                    ],
                  ),
                )
              else
                for (final p in lowStock.take(5))
                  _CompactProductRow(product: p, onTap: () => _openProduct(p)),
            ],
          ),
        );

        final recent = _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Recently added'),
              if (store.products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No products yet.'),
                )
              else
                for (final p in store.products.take(5))
                  _CompactProductRow(
                    product: p,
                    onTap: () => _openProduct(p),
                    showDate: true,
                  ),
            ],
          ),
        );

        // Third-party API card; it loads its own data, separate from the products.
        final valueAbroad = InventoryValueAbroadCard(
          totalValuePhp: store.totalValue,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inventory overview', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Updated ${Formatters.date(DateTime.now())}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _KpiGrid(
              width: width,
              items: [
                _Kpi(
                  'Total products',
                  store.products.length.toString(),
                  Icons.inventory_2_outlined,
                  theme.colorScheme.primary,
                ),
                _Kpi(
                  'Stock value',
                  Formatters.compactMoney(store.totalValue),
                  Icons.payments_outlined,
                  const Color(0xFF4338CA),
                ),
                _Kpi(
                  'Low stock',
                  lowStock.length.toString(),
                  Icons.warning_amber_rounded,
                  const Color(0xFFB45309),
                ),
                _Kpi(
                  'Categories',
                  store.categories.length.toString(),
                  Icons.category_outlined,
                  const Color(0xFF0369A1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (twoColumn) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: overview),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: restock),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: recent),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: valueAbroad),
                  ],
                ),
              ),
            ] else ...[
              restock,
              const SizedBox(height: 16),
              overview,
              const SizedBox(height: 16),
              recent,
              const SizedBox(height: 16),
              valueAbroad,
            ],
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.width, required this.items});

  final double width;
  final List<_Kpi> items;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    final columns = width >= 760 ? 4 : 2;
    final itemWidth = (width - spacing * (columns - 1)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final item in items)
          SizedBox(
            width: itemWidth,
            child: _KpiCard(item: item),
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final _Kpi item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(item.value, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.entries, required this.total});

  final List<MapEntry<String, double>> entries;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) return const Text('No data yet.');

    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CategoryStyle.icon(e.key),
                      size: 16,
                      color: CategoryStyle.color(e.key),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.money(e.value),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${total == 0 ? 0 : (e.value / total * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : e.value / total,
                    minHeight: 6,
                    color: CategoryStyle.color(e.key),
                    backgroundColor: CategoryStyle.color(
                      e.key,
                    ).withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompactProductRow extends StatelessWidget {
  const _CompactProductRow({
    required this.product,
    required this.onTap,
    this.showDate = false,
  });

  final DryGood product;
  final VoidCallback onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = StockStatus.of(product);
    final muted = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            CategoryAvatar(category: product.category, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    showDate
                        ? '${product.category} · ${Formatters.date(product.createdAt)}'
                        : product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (showDate)
              Text(
                Formatters.money(product.price),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                '${Formatters.quantity(product.quantity)} ${product.unit}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
