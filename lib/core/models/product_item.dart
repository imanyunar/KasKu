class ProductItem {
  final int? id;
  final String name;
  final double defaultPrice;
  final String defaultUnit;

  ProductItem({
    this.id,
    required this.name,
    required this.defaultPrice,
    required this.defaultUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'defaultPrice': defaultPrice,
      'defaultUnit': defaultUnit,
    };
  }

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      id: map['id'],
      name: map['name'],
      defaultPrice: map['defaultPrice'],
      defaultUnit: map['defaultUnit'],
    );
  }
}
