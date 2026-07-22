import 'dart:io';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:catatkas/core/database/database_helper.dart';
import 'package:catatkas/core/models/transaction_item.dart';

class BackupHelper {
  /// Ekspor data ke file CSV di folder Download
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
    if (transactions.isEmpty) {
      throw Exception("Data transaksi masih kosong. Tidak ada yang dibackup.");
    }

    // 3. Konversi ke Format CSV
    List<List<dynamic>> csvData = [
      // Header
      ["ID", "Jenis", "Nama Barang", "Jumlah", "Satuan", "Total Harga", "Tanggal"]
    ];

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

    String csvString = const ListToCsvConverter().convert(csvData);

    // 4. Simpan ke Folder Download
    // Hardcode path untuk folder Download utama di Android
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/CatatKas_Backup_$timestamp.csv');
    
    await file.writeAsString(csvString);
    
    return file.path;
  }

  /// Import data dari file CSV
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

    // Lewati baris pertama (Header)
    int importedCount = 0;
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.length >= 7) {
        // Asumsi format: ["ID", "Jenis", "Nama Barang", "Jumlah", "Satuan", "Total Harga", "Tanggal"]
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

        final item = TransactionItem(
          isJual: isJual,
          name: name,
          qty: qty,
          unit: unit,
          price: price,
          timestamp: timestamp,
        );

        await DatabaseHelper.instance.insertTransaction(item);
        importedCount++;
      }
    }
    return importedCount;
  }
}
