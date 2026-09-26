class DryGood {
  final int? id;
  final String productName;
  final String category;
  final double quantity;
  final String unit;
  final double price;
  final String? supplier;
  final String? description;
  final DateTime? createdAt;

  const DryGood({
    this.id,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    this.supplier,
    this.description,
    this.createdAt,
  });

  static String _textFromJson(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  static double _doubleFromJson(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value == null) {
      return 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  factory DryGood.fromJson(Map<String, dynamic> json) {
    return DryGood(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      productName: _textFromJson(json['product_name']).trim(),
      category: _textFromJson(json['category']).trim(),
      quantity: _doubleFromJson(json['quantity']),
      unit: _textFromJson(json['unit']).trim(),
      price: _doubleFromJson(json['price']),
      supplier:
          json['supplier'] == null || json['supplier'].toString().trim().isEmpty
          ? null
          : json['supplier'].toString().trim(),
      description:
          json['description'] == null ||
              json['description'].toString().trim().isEmpty
          ? null
          : json['description'].toString().trim(),
      createdAt: _dateFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'supplier': supplier,
      'description': description,
    };
  }

  DryGood copyWith({
    int? id,
    String? productName,
    String? category,
    double? quantity,
    String? unit,
    double? price,
    String? supplier,
    String? description,
    DateTime? createdAt,
  }) {
    return DryGood(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      supplier: supplier ?? this.supplier,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
