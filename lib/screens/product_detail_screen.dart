import 'package:flutter/material.dart';

import '../models/dry_good.dart';
import '../services/api_service.dart';
import '../services/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final DryGood product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isDeleting = false;

  Future<void> _edit(DryGood product) async {
    final saved = await Navigator.push<DryGood>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (saved != null && mounted) showAppSnackBar(context, 'Changes saved.');
  }

  Future<void> _confirmDelete(DryGood product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
        title: const Text('Delete product?'),
        content: Text(
          '“${product.productName}” will be permanently removed from the inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || product.id == null || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await InventoryScope.read(context).delete(product.id!);
      if (!mounted) return;
      showAppSnackBar(context, '“${product.productName}” deleted.');
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (mounted) showAppSnackBar(context, error.message, isError: true);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Delete failed: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the store's copy so edits made from this screen show immediately.
    final product =
        InventoryScope.of(context).byId(widget.product.id) ?? widget.product;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final status = StockStatus.of(product);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _edit(product),
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ContentWidth(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryAvatar(category: product.category, size: 60),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.category,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              StockBadge(status: status),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'On hand',
                        value: Formatters.quantity(product.quantity),
                        caption: product.unit,
                        color: status.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: 'Unit price',
                        value: Formatters.money(product.price),
                        caption: 'per ${product.unit}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: 'Stock value',
                        value: Formatters.compactMoney(
                          product.price * product.quantity,
                        ),
                        caption: 'total',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.local_shipping_outlined,
                        label: 'Supplier',
                        value: product.supplier ?? 'Not provided',
                      ),
                      const Divider(indent: 56),
                      _DetailRow(
                        icon: Icons.straighten_rounded,
                        label: 'Unit of measure',
                        value: product.unit,
                      ),
                      const Divider(indent: 56),
                      _DetailRow(
                        icon: Icons.event_outlined,
                        label: 'Added on',
                        value: Formatters.date(product.createdAt),
                      ),
                      const Divider(indent: 56),
                      _DetailRow(
                        icon: Icons.tag_rounded,
                        label: 'Product ID',
                        value: product.id == null ? '—' : '#${product.id}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description ?? 'No description provided.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: product.description == null ? muted : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ContentWidth(
            maxWidth: 760,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: BorderSide(
                        color: AppTheme.danger.withValues(alpha: 0.5),
                      ),
                    ),
                    onPressed: _isDeleting
                        ? null
                        : () => _confirmDelete(product),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isDeleting ? null : () => _edit(product),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.caption,
    this.color,
  });

  final String label;
  final String value;
  final String caption;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(color: color),
              ),
            ),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 18),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
