import 'dart:io';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:catatkas/core/database/database_helper.dart';
import 'package:catatkas/core/models/transaction_item.dart';
import 'package:catatkas/core/models/product_item.dart';

class BackupHelper {
  /// Ekspor data transaksi DAN produk ke file CSV di folder Download
  static Future<String> exportToCsv() async {
    // 1. Meminta Izin Akses Memori
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted || 
          await Permission.storage.request().isGranted) {
        // Izin diberikan
      } else {
        throw Exception("Izin penyimpanan ditolak. Tidak bisa melakukan backup.");
      }
    }

    // 2. Ambil data dari SQLite
    final transactions = await DatabaseHelper.instance.getAllTransactions();
    final products = await DatabaseHelper.instance.getAllProducts();

    if (transactions.isEmpty && products.isEmpty) {
      throw Exception("Data masih kosong. Tidak ada yang dibackup.");
    }

    // 3. Konversi ke Format CSV (dengan section markers)
    List<List<dynamic>> csvData = [];

    // Section: Transaksi
    csvData.add(["[TRANSAKSI]"]);
    csvData.add(["ID", "Jenis", "Nama Barang", "Jumlah", "Satuan", "Total Harga", "Tanggal"]);
    for (var item in transactions) {
      csvData.add([
        item.id,
        item.isJual ? "Jual/Pemasukan" : "Beli/Pengeluaran",
        item.name,
        item.qty,
        item.unit,
        item.price,
        item.timestamp.toIso8601String(),
      ]);
    }

    // Section: Produk
    csvData.add([]); // Baris kosong pemisah
    csvData.add(["[PRODUK]"]);
    csvData.add(["ID", "Nama", "Harga Default", "Satuan Default"]);
    for (var item in products) {
      csvData.add([
        item.id,
        item.name,
        item.defaultPrice,
        item.defaultUnit,
      ]);
    }

    String csvString = const ListToCsvConverter().convert(csvData);

    // 4. Simpan ke Folder Download
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/CatatKas_Backup_$timestamp.csv');
    
    await file.writeAsString(csvString);
    
    return file.path;
  }

  /// Import data dari file CSV (mendukung format lama dan baru)
  static Future<int> importFromCsv(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("File CSV tidak ditemukan.");
    }

    final csvString = await file.readAsString();
    List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

    if (csvData.isEmpty || csvData.length == 1) {
      throw Exception("File CSV kosong atau tidak valid.");
    }

    int importedCount = 0;

    // Deteksi format: baru (ada marker [TRANSAKSI]) atau lama (langsung header)
    final bool isNewFormat = csvData[0].isNotEmpty &&
        csvData[0][0].toString().trim() == '[TRANSAKSI]';

    if (isNewFormat) {
      String currentSection = '';
      for (int i = 0; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.isEmpty) continue;

        final firstCell = row[0].toString().trim();

        if (firstCell == '[TRANSAKSI]') {
          currentSection = 'TRANSAKSI';
          continue;
        }
        if (firstCell == '[PRODUK]') {
          currentSection = 'PRODUK';
          continue;
        }
        // Skip header rows
        if (firstCell == 'ID') continue;

        if (currentSection == 'TRANSAKSI' && row.length >= 7) {
          final item = _parseTransactionRow(row);
          await DatabaseHelper.instance.insertTransaction(item);
          importedCount++;
        } else if (currentSection == 'PRODUK' && row.length >= 4) {
          final item = ProductItem(
            name: row[1].toString(),
            defaultPrice: double.tryParse(row[2].toString()) ?? 0.0,
            defaultUnit: row[3].toString(),
          );
          await DatabaseHelper.instance.insertProduct(item);
          importedCount++;
        }
      }
    } else {
      // Format lama: lewati baris pertama (Header), semua baris = transaksi
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length >= 7) {
          final item = _parseTransactionRow(row);
          await DatabaseHelper.instance.insertTransaction(item);
          importedCount++;
        }
      }
    }
    return importedCount;
  }

  /// Helper: parse satu baris CSV menjadi TransactionItem
  static TransactionItem _parseTransactionRow(List<dynamic> row) {
    final isJual = row[1].toString().contains("Jual");
    final name = row[2].toString();
    final qty = double.tryParse(row[3].toString()) ?? 1.0;
    final unit = row[4].toString();
    final price = double.tryParse(row[5].toString()) ?? 0.0;
    final timestampStr = row[6].toString();

    DateTime timestamp;
    try {
      timestamp = DateTime.parse(timestampStr);
    } catch (e) {
      timestamp = DateTime.now();
    }

    return TransactionItem(
      isJual: isJual,
      name: name,
      qty: qty,
      unit: unit,
      price: price,
      timestamp: timestamp,
    );
  }
}
