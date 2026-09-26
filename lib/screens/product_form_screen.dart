import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../models/dry_good.dart';
import '../services/api_service.dart';
import '../services/inventory_store.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

/// Add a new product, or edit [product] when given. Pops with the saved
/// [DryGood] on success.
class ProductFormScreen extends StatefulWidget {
  final DryGood? product;

  const ProductFormScreen({super.key, this.product});

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.product?.productName,
  );
  late final _categoryController = TextEditingController(
    text: widget.product?.category,
  );
  late final _quantityController = TextEditingController(
    text: widget.product == null
        ? null
        : Formatters.quantity(widget.product!.quantity).replaceAll(',', ''),
  );
  late final _unitController = TextEditingController(
    text: widget.product?.unit,
  );
  late final _priceController = TextEditingController(
    text: widget.product?.price.toStringAsFixed(2),
  );
  late final _supplierController = TextEditingController(
    text: widget.product?.supplier,
  );
  late final _descriptionController = TextEditingController(
    text: widget.product?.description,
  );

  bool _isSubmitting = false;

  static final _decimalInput = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*\.?\d{0,2}'),
  );

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _categoryController,
      _quantityController,
      _unitController,
      _priceController,
      _supplierController,
      _descriptionController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? '$field is required.' : null;

  String? _nonNegativeNumber(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) return '$field must be a number ≥ 0.';
    return null;
  }

  String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final store = InventoryScope.read(context);

    final values = DryGood(
      id: widget.product?.id,
      createdAt: widget.product?.createdAt,
      productName: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      quantity: double.parse(_quantityController.text.trim()),
      unit: _unitController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      supplier: _optional(_supplierController),
      description: _optional(_descriptionController),
    );

    try {
      final saved = widget.isEditing
          ? await store.update(values)
          : await store.create(values);
      if (mounted) Navigator.pop(context, saved);
    } on ApiException catch (error) {
      if (mounted) showAppSnackBar(context, error.message, isError: true);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Save failed: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = InventoryScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit product' : 'New product'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              Widget pair(Widget a, Widget b) => wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: a),
                        const SizedBox(width: 12),
                        Expanded(child: b),
                      ],
                    )
                  : Column(children: [a, const SizedBox(height: 14), b]);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  ContentWidth(
                    maxWidth: 760,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FormSection(
                          title: 'Product information',
                          icon: Icons.info_outline_rounded,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Product name *',
                                prefixIcon: Icon(Icons.label_outline_rounded),
                                counterText: '',
                              ),
                              validator: (v) => _required(v, 'Product name'),
                            ),
                            const SizedBox(height: 14),
                            _SuggestionField(
                              controller: _categoryController,
                              suggestions: store.categories,
                              label: 'Category *',
                              icon: Icons.category_outlined,
                              maxLength: 50,
                              validator: (v) => _required(v, 'Category'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FormSection(
                          title: 'Stock & pricing',
                          icon: Icons.payments_outlined,
                          children: [
                            pair(
                              TextFormField(
                                controller: _quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [_decimalInput],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity *',
                                  prefixIcon: Icon(Icons.numbers_rounded),
                                  helperText:
                                      'Low stock at ${AppConfig.lowStockThreshold} or below',
                                ),
                                validator: (v) =>
                                    _nonNegativeNumber(v, 'Quantity'),
                              ),
                              _SuggestionField(
                                controller: _unitController,
                                suggestions: {
                                  ...store.units,
                                  'kg',
                                  'pack',
                                  'can',
                                  'box',
                                  'bag',
                                  'bottle',
                                  'sack',
                                }.toList()..sort(),
                                label: 'Unit *',
                                icon: Icons.straighten_rounded,
                                maxLength: 20,
                                validator: (v) => _required(v, 'Unit'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [_decimalInput],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Unit price *',
                                prefixIcon: const Icon(Icons.sell_outlined),
                                prefixText: '${AppConfig.currencySymbol} ',
                              ),
                              validator: (v) => _nonNegativeNumber(v, 'Price'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FormSection(
                          title: 'Additional details',
                          icon: Icons.notes_rounded,
                          children: [
                            TextFormField(
                              controller: _supplierController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Supplier',
                                prefixIcon: Icon(Icons.local_shipping_outlined),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descriptionController,
                              minLines: 3,
                              maxLines: 6,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _isSubmitting ? null : _submit,
                                icon: _isSubmitting
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : Icon(
                                        widget.isEditing
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                      ),
                                label: Text(
                                  widget.isEditing
                                      ? 'Save changes'
                                      : 'Add product',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Free-text field that also suggests existing values (categories, units),
/// keeping data consistent without restricting new entries.
class _SuggestionField extends StatefulWidget {
  const _SuggestionField({
    required this.controller,
    required this.suggestions,
    required this.label,
    required this.icon,
    required this.validator,
    this.maxLength,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final int? maxLength;

  @override
  State<_SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<_SuggestionField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        return widget.suggestions.where(
          (s) => s.toLowerCase().contains(query) && s.toLowerCase() != query,
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: Icon(widget.icon),
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
              counterText: '',
            ),
            validator: widget.validator,
          ),
      optionsViewBuilder: (context, onSelected, options) {
        final theme = Theme.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      dense: true,
                      title: Text(option),
                      onTap: () => onSelected(option),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
