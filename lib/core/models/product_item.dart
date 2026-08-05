class ProductItem {
  final int? id;
  final String name;
  final double defaultPrice;
  final String defaultUnit;
  final double stock;

  ProductItem({
    this.id,
    required this.name,
    required this.defaultPrice,
    required this.defaultUnit,
    this.stock = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'defaultPrice': defaultPrice,
      'defaultUnit': defaultUnit,
      'stock': stock,
    };
  }

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      id: map['id'],
      name: map['name'],
      defaultPrice: (map['defaultPrice'] as num).toDouble(),
      defaultUnit: map['defaultUnit'],
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
    );
  }

  ProductItem copyWith({double? stock}) {
    return ProductItem(
      id: id,
      name: name,
      defaultPrice: defaultPrice,
      defaultUnit: defaultUnit,
      stock: stock ?? this.stock,
    );
  }
}
