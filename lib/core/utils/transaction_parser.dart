import 'package:catatkas/core/models/transaction_item.dart';

class TransactionParser {
  static const List<String> _pemasukanKeywords = [
    'penjualan', 'jual', 'pemasukan', 'terima', 'pendapatan', 'omset', 'laku', 'dapat', 'laba', 'setoran'
  ];

  static const List<String> _pengeluaranKeywords = [
    'pembelian', 'beli', 'bayar', 'kulakan', 'belanja', 'biaya', 'pengeluaran', 'ongkir', 'gaji', 'sewa', 'listrik', 'air', 'dinas', 'servis', 'reparasi'
  ];

  /// Detect whether the typed text represents Pemasukan or Pengeluaran
  static bool? detectIsJual(String input) {
    input = input.trim().toLowerCase();
    for (var kw in _pemasukanKeywords) {
      if (input.startsWith('$kw ') || input == kw) return true;
    }
    for (var kw in _pengeluaranKeywords) {
      if (input.startsWith('$kw ') || input == kw) return false;
    }
    return null;
  }

  /// Parsing string input cepat (Quick Input).
  /// Contoh 1: "jual bawang merah 1kg 20rb"
  /// Contoh 2: "pembelian 3 gram telur 200rb"
  /// Contoh 3: "penjualan bawang goreng 100 ons 250rb"
  static TransactionItem parse(String input, {bool defaultIsJual = true}) {
    input = input.trim();
    if (input.isEmpty) {
      throw const FormatException("Ketikkan data transaksi terlebih dahulu.");
    }

    String lowerInput = input.toLowerCase();
    bool isJual = defaultIsJual;
    String cleanInput = input;

    // 1. Cek kata kunci aksi (penjualan/pembelian/jual/beli/dll)
    for (var kw in _pemasukanKeywords) {
      if (lowerInput.startsWith('$kw ')) {
        isJual = true;
        cleanInput = input.substring(kw.length).trim();
        break;
      }
    }
    for (var kw in _pengeluaranKeywords) {
      if (lowerInput.startsWith('$kw ')) {
        isJual = false;
        cleanInput = input.substring(kw.length).trim();
        break;
      }
    }

    // 2. Pola Regex A: [Nama] [Qty] [Unit] [Price] (Contoh: "bawang goreng 100 ons 250rb" / "bawang merah 1kg 20rb")
    final RegExp regexA = RegExp(
      r'^(.*?)\s+([\d.,]+)\s*([a-zA-Z]+)?\s+([\d.,]+)\s*(rb|ribu|jt|juta)?$',
      caseSensitive: false,
    );

    // 3. Pola Regex B: [Qty] [Unit] [Nama] [Price] (Contoh: "3 gram telur 200rb" / "100 ons bawang 250rb")
    final RegExp regexB = RegExp(
      r'^([\d.,]+)\s*([a-zA-Z]+)?\s+(.*?)\s+([\d.,]+)\s*(rb|ribu|jt|juta)?$',
      caseSensitive: false,
    );

    Match? match = regexA.firstMatch(cleanInput);
    bool isTypeB = false;

    if (match == null || (match.group(1)?.trim().isEmpty ?? true)) {
      match = regexB.firstMatch(cleanInput);
      isTypeB = true;
    }

    if (match == null) {
      throw const FormatException(
          "Format tidak dikenali.\nContoh: 'pembelian 3 gram telur 200rb' atau 'penjualan bawang 1kg 20rb'");
    }

    String name = "";
    String qtyStr = "1";
    String unit = "pcs";
    String priceStr = "0";
    String? nominalStr;

    if (!isTypeB) {
      // Form A: [Name] [Qty] [Unit] [Price]
      name = match.group(1)?.trim() ?? "";
      qtyStr = match.group(2)?.replaceAll(',', '.') ?? "1";
      unit = match.group(3)?.trim() ?? "pcs";
      priceStr = match.group(4) ?? "0";
      nominalStr = match.group(5)?.toLowerCase();
    } else {
      // Form B: [Qty] [Unit] [Name] [Price]
      qtyStr = match.group(1)?.replaceAll(',', '.') ?? "1";
      unit = match.group(2)?.trim() ?? "pcs";
      name = match.group(3)?.trim() ?? "";
      priceStr = match.group(4) ?? "0";
      nominalStr = match.group(5)?.toLowerCase();
    }

    if (name.isEmpty) {
      throw const FormatException("Nama barang tidak boleh kosong.");
    }

    final qty = double.tryParse(qtyStr) ?? 1.0;

    // Parsing Harga (Indonesian locale: 30.000 -> 30000, 30,5 -> 30.5)
    priceStr = priceStr.replaceAll('.', '').replaceAll(',', '.');
    double price = double.tryParse(priceStr) ?? 0.0;

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
      unit: unit.isEmpty ? "pcs" : unit,
      price: price,
      timestamp: DateTime.now(),
    );
  }
}
