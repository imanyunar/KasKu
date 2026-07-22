import 'package:catatkas/core/models/transaction_item.dart';

class TransactionParser {
  /// Mencoba parsing string input cepat (Quick Input).
  /// Contoh: "jual bawang merah 1kg 20rb"
  /// Kembalian: [TransactionItem] jika sukses, melempar exception jika gagal.
  static TransactionItem parse(String input, {bool defaultIsJual = true}) {
    input = input.trim();
    if (input.isEmpty) {
      throw const FormatException("Ketikkan data transaksi terlebih dahulu.");
    }

    // Pola Regex:
    // 1. (jual|beli)? -> Opsional awalan (case-insensitive)
    // 2. (.*?) -> Nama barang (non-greedy)
    // 3. ([\d.,]+) -> Kuantitas (angka, koma, titik)
    // 4. ([a-zA-Z]+)? -> Satuan opsional (kg, pcs, liter, dll)
    // 5. ([\d.,]+) -> Harga (angka, koma, titik)
    // 6. (rb|ribu|jt|juta)? -> Singkatan nominal opsional
    final RegExp regex = RegExp(
      r'^(?:(jual|beli)\s+)?(.*?)\s+([\d.,]+)\s*([a-zA-Z]+)?\s+([\d.,]+)\s*(rb|ribu|jt|juta)?$',
      caseSensitive: false,
    );

    final match = regex.firstMatch(input);
    if (match == null) {
      throw const FormatException(
          "Format tidak dikenali. \nContoh yang benar: 'bawang merah 1kg 20rb'");
    }

    // Ekstrak Tipe Transaksi (jika diketik, menimpa default dari toggle UI)
    bool isJual = defaultIsJual;
    final typeStr = match.group(1)?.toLowerCase();
    if (typeStr == 'jual') {
      isJual = true;
    } else if (typeStr == 'beli') {
      isJual = false;
    }

    // Ekstrak Nama Barang
    final name = match.group(2)?.trim() ?? "";
    if (name.isEmpty) {
      throw const FormatException("Nama barang tidak boleh kosong.");
    }

    // Ekstrak Kuantitas
    final qtyStr = match.group(3)?.replaceAll(',', '.') ?? "1";
    final qty = double.tryParse(qtyStr) ?? 1.0;

    // Ekstrak Satuan
    final unit = match.group(4)?.trim() ?? "pcs";

    // Ekstrak Harga (Indonesian locale: 30.000 -> 30000, 30,5 -> 30.5)
    String priceStr = match.group(5) ?? "0";
    // 1. Hapus semua titik (sebagai pemisah ribuan)
    priceStr = priceStr.replaceAll('.', '');
    // 2. Ganti koma dengan titik (sebagai pemisah desimal)
    priceStr = priceStr.replaceAll(',', '.');
    double price = double.tryParse(priceStr) ?? 0.0;

    // Ekstrak Nominal / Pengali Uang
    final nominalStr = match.group(6)?.toLowerCase();
    if (nominalStr == 'rb' || nominalStr == 'ribu') {
      price *= 1000;
    } else if (nominalStr == 'jt' || nominalStr == 'juta') {
      price *= 1000000;
    }

    if (price <= 0) {
      throw const FormatException("Harga tidak boleh nol.");
    }

    return TransactionItem(
      isJual: isJual,
      name: name,
      qty: qty,
      unit: unit,
      price: price,
      timestamp: DateTime.now(),
    );
  }
}
