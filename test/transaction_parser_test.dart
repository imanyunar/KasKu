import 'package:flutter_test/flutter_test.dart';
import 'package:catatkas/core/utils/transaction_parser.dart';
import 'package:catatkas/core/models/transaction_item.dart';

void main() {
  group('TransactionParser - Skenario Valid', () {
    test('TC-01: Format Standar Pemasukan (Jual)', () {
      final item = TransactionParser.parse("jual bawang merah 1kg 15rb");
      
      expect(item.isJual, isTrue);
      expect(item.name, "bawang merah");
      expect(item.qty, 1.0);
      expect(item.unit, "kg");
      expect(item.price, 15000.0);
    });

    test('TC-02: Format Standar Pengeluaran (Beli)', () {
      final item = TransactionParser.parse("beli minyak goreng 2 liter 30.000");
      
      expect(item.isJual, isFalse);
      expect(item.name, "minyak goreng");
      expect(item.qty, 2.0);
      expect(item.unit, "liter");
      expect(item.price, 30000.0);
    });

    test('TC-04: Format Juta (jt)', () {
      final item = TransactionParser.parse("jual beras 5 kg 50jt");
      
      expect(item.isJual, isTrue);
      expect(item.name, "beras");
      expect(item.qty, 5.0);
      expect(item.unit, "kg");
      expect(item.price, 50000000.0);
    });

    test('TC-06: Tanpa kata Jual/Beli di awal (Menggunakan default)', () {
      // Jika toggle di UI sedang di "Beli" (false)
      final item = TransactionParser.parse("bawang merah 1kg 15rb", defaultIsJual: false);
      
      expect(item.isJual, isFalse); // Mengikuti default
      expect(item.name, "bawang merah");
      expect(item.qty, 1.0);
      expect(item.price, 15000.0);
    });
    
    test('TC-03: Typo tanpa spasi di kata awal (jualbawang)', () {
      // Regex mewajibkan spasi setelah kata jual/beli. 
      // Jika tidak ada spasi, kata 'jualbawang' akan ditangkap sebagai nama barang, dan tipe mengikuti default.
      final item = TransactionParser.parse("jualbawang 2kg 10rb", defaultIsJual: true);
      
      expect(item.isJual, isTrue); 
      expect(item.name, "jualbawang");
      expect(item.qty, 2.0);
      expect(item.unit, "kg");
      expect(item.price, 10000.0);
    });
  });

  group('TransactionParser - Skenario Tidak Valid (Menghasilkan Exception)', () {
    test('TC-05: Singkatan harga tidak dikenali (k)', () {
      expect(
        () => TransactionParser.parse("beli sabun 3pcs 15k"),
        throwsA(isA<FormatException>()),
      );
    });

    test('TC-07: Tidak ada kuantitas atau harga', () {
      expect(
        () => TransactionParser.parse("jual bawang 15rb"),
        throwsA(isA<FormatException>()), // Gagal dicocokkan regex karena butuh 2 grup angka
      );
    });

    test('TC-08: Tidak ada nama barang', () {
      expect(
        () => TransactionParser.parse("jual 1kg 15rb"),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', "Nama barang tidak boleh kosong.")
        ),
      );
    });

    test('TC-09: Tidak ada kuantitas, hanya nama dan harga', () {
      expect(
        () => TransactionParser.parse("beli token listrik 100rb"),
        throwsA(isA<FormatException>()), // Gagal dicocokkan regex
      );
    });
  });
}
