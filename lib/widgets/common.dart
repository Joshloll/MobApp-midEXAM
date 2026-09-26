import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/dry_good.dart';
import '../screens/settings_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

enum StockStatus {
  outOfStock(
    'Out of stock',
    AppTheme.danger,
    Icons.remove_shopping_cart_outlined,
  ),
  low('Low stock', AppTheme.warning, Icons.warning_amber_rounded),
  inStock('In stock', AppTheme.success, Icons.check_circle_outline_rounded);

  const StockStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static StockStatus of(DryGood product) {
    if (product.quantity <= 0) return StockStatus.outOfStock;
    if (product.quantity <= AppConfig.lowStockThreshold) return StockStatus.low;
    return StockStatus.inStock;
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.status, this.dense = false});

  final StockStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent icon + tint per category, so products are recognisable at a glance.
class CategoryStyle {
  static const _palette = [
    Color(0xFF0F766E),
    Color(0xFF4338CA),
    Color(0xFFB45309),
    Color(0xFFBE185D),
    Color(0xFF0369A1),
    Color(0xFF7C3AED),
    Color(0xFF15803D),
    Color(0xFFC2410C),
  ];

  static IconData icon(String category) {
    final c = category.toLowerCase();
    if (c.contains('rice') || c.contains('grain')) {
      return Icons.rice_bowl_outlined;
    }
    if (c.contains('noodle')) return Icons.ramen_dining_outlined;
    if (c.contains('pasta')) return Icons.dinner_dining_outlined;
    if (c.contains('coffee') || c.contains('tea')) return Icons.coffee_outlined;
    if (c.contains('flour') || c.contains('bread') || c.contains('bak')) {
      return Icons.bakery_dining_outlined;
    }
    if (c.contains('biscuit') || c.contains('cookie') || c.contains('snack')) {
      return Icons.cookie_outlined;
    }
    if (c.contains('sugar') || c.contains('sweet')) {
      return Icons.icecream_outlined;
    }
    if (c.contains('can')) return Icons.soup_kitchen_outlined;
    if (c.contains('oil') || c.contains('sauce') || c.contains('condiment')) {
      return Icons.water_drop_outlined;
    }
    if (c.contains('drink') || c.contains('beverage')) {
      return Icons.local_drink_outlined;
    }
    return Icons.category_outlined;
  }

  static Color color(String category) {
    final hash = category.toLowerCase().codeUnits.fold<int>(
      0,
      (h, c) => (h * 31 + c) & 0x7fffffff,
    );
    return _palette[hash % _palette.length];
  }
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 44});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.color(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        CategoryStyle.icon(category),
        color: color,
        size: size * 0.52,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Centers content and caps its width so layouts stay readable on tablets,
/// desktops and wide browser windows.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1100});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Full-area message for empty and error states.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
    this.color,
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;
  final Color? color;

  factory StateMessage.error(
    BuildContext context,
    ApiException error,
    VoidCallback onRetry,
  ) {
    return StateMessage(
      icon: error.isConnectionError
          ? Icons.cloud_off_rounded
          : Icons.error_outline_rounded,
      title: error.isConnectionError
          ? 'Can’t connect to the server'
          : 'Something went wrong',
      message: error.isConnectionError
          ? '${error.message}\nMake sure Apache and MySQL are running in XAMPP and the server URL is correct.'
          : error.message,
      color: Theme.of(context).colorScheme.error,
      actions: [
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
        if (error.isConnectionError)
          OutlinedButton.icon(
            onPressed: () => SettingsScreen.open(context),
            icon: const Icon(Icons.dns_outlined),
            label: const Text('Server settings'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: tint),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? scheme.onError : scheme.onInverseSurface,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
}
