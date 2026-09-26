import 'package:flutter/material.dart';

import '../models/dry_good.dart';
import '../utils/formatters.dart';
import 'common.dart';

class ProductCard extends StatelessWidget {
  final DryGood product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final status = StockStatus.of(product);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryAvatar(category: product.category),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        product.category,
                        if (product.supplier != null) product.supplier!,
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StockBadge(status: status, dense: true),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '${Formatters.quantity(product.quantity)} ${product.unit}',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.money(product.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'per ${product.unit}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
