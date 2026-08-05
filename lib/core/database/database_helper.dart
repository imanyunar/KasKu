import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:catatkas/core/models/transaction_item.dart';
import 'package:catatkas/core/models/product_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('catatkas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const realType = 'REAL NOT NULL';
      
      await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType,
  defaultPrice $realType,
  defaultUnit $textType,
  stock REAL NOT NULL DEFAULT 0
)
''');
    }
    if (oldVersion < 3) {
      // Tambah kolom stock untuk pengguna yang sudah punya tabel products
      try {
        await db.execute('ALTER TABLE products ADD COLUMN stock REAL NOT NULL DEFAULT 0');
      } catch (_) {
        // Kolom sudah ada (jika user baru install langsung dari v3)
      }
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  isJual $boolType,
  name $textType,
  qty $realType,
  unit $textType,
  price $realType,
  timestamp $textType
)
''');

    await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType,
  defaultPrice $realType,
  defaultUnit $textType,
  stock $realType DEFAULT 0
)
''');
  }

  // --- Fungsi Create ---
  Future<TransactionItem> insertTransaction(TransactionItem item) async {
    final db = await instance.database;
    final id = await db.insert('transactions', item.toMap());
    return TransactionItem(
      id: id,
      isJual: item.isJual,
      name: item.name,
      qty: item.qty,
      unit: item.unit,
      price: item.price,
      timestamp: item.timestamp,
    );
  }

  // --- Fungsi Read (All) ---
  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await instance.database;

    // Menampilkan dari yang paling baru
    final result = await db.query('transactions', orderBy: 'timestamp DESC');

    return result.map((json) => TransactionItem.fromMap(json)).toList();
  }

  // --- Fungsi Read (Total Saldo Akumulatif Kas Saat Ini) ---
  Future<double> getTotalSaldo() async {
    final db = await instance.database;
    final result = await db.query('transactions');

    double totalPemasukan = 0;
    double totalPengeluaran = 0;

    for (var row in result) {
      final isJual = row['isJual'] == 1;
      final price = row['price'] as double;
      if (isJual) {
        totalPemasukan += price;
      } else {
        totalPengeluaran += price;
      }
    }

    return totalPemasukan - totalPengeluaran;
  }

  // --- Fungsi Read (Laba/Rugi Harian) ---
  Future<double> getDailySaldo() async {
    final db = await instance.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final result = await db.query(
      'transactions',
      where: 'timestamp >= ?',
      whereArgs: [todayStart],
    );

    double totalPemasukan = 0;
    double totalPengeluaran = 0;

    for (var row in result) {
      final isJual = row['isJual'] == 1;
      final price = row['price'] as double;
      if (isJual) {
        totalPemasukan += price;
      } else {
        totalPengeluaran += price;
      }
    }

    return totalPemasukan - totalPengeluaran;
  }

  // --- Fungsi Laporan (Range Waktu) ---
  Future<Map<String, double>> getReportSummary(DateTime start, DateTime end) async {
    final db = await instance.database;
    final startStr = start.toIso8601String();
    // Untuk end, kita ambil sampai penghujung hari (23:59:59.999)
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59, 999).toIso8601String();

    final result = await db.query(
      'transactions',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startStr, endStr],
    );

    double pemasukan = 0;
    double pengeluaran = 0;

    for (var row in result) {
      final isJual = row['isJual'] == 1;
      final price = row['price'] as double;
      if (isJual) {
        pemasukan += price;
      } else {
        pengeluaran += price;
      }
    }

    return {
      'pemasukan': pemasukan,
      'pengeluaran': pengeluaran,
      'untung': pemasukan - pengeluaran,
    };
  }

  // --- Fungsi Update ---
  Future<int> updateTransaction(TransactionItem item) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // --- Fungsi Delete ---
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // FUNGSI MANAJEMEN PRODUK (TAHAP 2)
  // ==========================================

  Future<ProductItem> insertProduct(ProductItem item) async {
    final db = await instance.database;
    final id = await db.insert('products', item.toMap());
    return ProductItem(
      id: id,
      name: item.name,
      defaultPrice: item.defaultPrice,
      defaultUnit: item.defaultUnit,
      stock: item.stock,
    );
  }

  Future<List<ProductItem>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => ProductItem.fromMap(json)).toList();
  }

  Future<int> updateProduct(ProductItem item) async {
    final db = await instance.database;
    return await db.update(
      'products',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Fungsi Update Stok ---
  Future<int> updateStock(int id, double newStock) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Kurangi stok otomatis berdasarkan nama produk.
  /// Dipanggil setelah transaksi berhasil disimpan.
  Future<void> deductStockByName(String productName, double qty) async {
    final db = await instance.database;
    final results = await db.query(
      'products',
      where: 'LOWER(name) = ?',
      whereArgs: [productName.toLowerCase()],
    );
    if (results.isNotEmpty) {
      final product = ProductItem.fromMap(results.first);
      final newStock = (product.stock - qty).clamp(0, double.infinity);
      await db.update(
        'products',
        {'stock': newStock},
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }
  }

  /// Tambah stok otomatis saat ada pembelian/beli bahan.
  Future<void> addStockByName(String productName, double qty) async {
    final db = await instance.database;
    final results = await db.query(
      'products',
      where: 'LOWER(name) = ?',
      whereArgs: [productName.toLowerCase()],
    );
    if (results.isNotEmpty) {
      final product = ProductItem.fromMap(results.first);
      final newStock = product.stock + qty;
      await db.update(
        'products',
        {'stock': newStock},
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
