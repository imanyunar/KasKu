class TransactionItem {
  final int? id;
  final bool isJual; // true = Pemasukan/Jual, false = Pengeluaran/Beli
  final String name;
  final double qty;
  final String unit;
  final double price;
  final DateTime timestamp;

  TransactionItem({
    this.id,
    required this.isJual,
    required this.name,
    required this.qty,
    required this.unit,
    required this.price,
    required this.timestamp,
  });

  // Konversi dari model ke Map (untuk SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isJual': isJual ? 1 : 0,
      'name': name,
      'qty': qty,
      'unit': unit,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Konversi dari Map (dari SQLite) ke model
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      isJual: map['isJual'] == 1,
      name: map['name'],
      qty: map['qty'],
      unit: map['unit'],
      price: map['price'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  String toString() {
    return 'TransactionItem{id: $id, isJual: $isJual, name: $name, qty: $qty, unit: $unit, price: $price, timestamp: $timestamp}';
  }
}
