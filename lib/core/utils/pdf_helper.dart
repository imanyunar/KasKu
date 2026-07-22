import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:catatkas/core/database/database_helper.dart';
import 'package:catatkas/core/models/transaction_item.dart';
import 'package:catatkas/core/utils/currency_formatter.dart';

class PdfExportResult {
  final String internalPath;
  final String? downloadPath;

  PdfExportResult({required this.internalPath, this.downloadPath});
}

class PdfHelper {
  /// Generate dan simpan Laporan PDF
  static Future<PdfExportResult> generateReportPdf(String periodLabel, DateTime start, DateTime end) async {
    // 1. Ambil data dari SQLite
    final db = await DatabaseHelper.instance.database;
    final startStr = start.toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    List<Map<String, dynamic>> result;
    if (periodLabel == 'SEMUA') {
      result = await db.query(
        'transactions',
        orderBy: 'timestamp ASC',
      );
    } else {
      result = await db.query(
        'transactions',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'timestamp ASC',
      );
    }

    final transactions = result.map((json) => TransactionItem.fromMap(json)).toList();

    if (transactions.isEmpty) {
      throw Exception("Data transaksi kosong pada periode ini.");
    }

    // 2. Kalkulasi Total
    double totalPemasukan = 0;
    double totalPengeluaran = 0;
    for (var item in transactions) {
      if (item.isJual) {
        totalPemasukan += item.price;
      } else {
        totalPengeluaran += item.price;
      }
    }
    double labaBersih = totalPemasukan - totalPengeluaran;

    // 3. Bikin Dokumen PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("Laporan Keuangan CatatKas UMKM", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text("Periode: $periodLabel", style: const pw.TextStyle(fontSize: 14)),
            pw.Text("Tanggal Cetak: ${DateTime.now().toString().split('.')[0]}", style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            
            // Tabel Transaksi
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Tanggal', 'Jenis', 'Nama Barang', 'Qty', 'Harga'],
              data: List<List<dynamic>>.generate(
                transactions.length,
                (index) {
                  final item = transactions[index];
                  final dateOnly = '${item.timestamp.day.toString().padLeft(2, '0')}/${item.timestamp.month.toString().padLeft(2, '0')}/${item.timestamp.year}';
                  final qtyDisplay = item.qty % 1 == 0 ? item.qty.toInt().toString() : item.qty.toString();
                  return [
                    index + 1,
                    dateOnly,
                    item.isJual ? 'Pemasukan' : 'Pengeluaran',
                    item.name,
                    '$qtyDisplay ${item.unit}',
                    CurrencyFormatter.format(item.price)
                  ];
                },
              ),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            
            pw.SizedBox(height: 24),
            pw.Divider(),
            
            // Ringkasan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Total Pemasukan : ${CurrencyFormatter.format(totalPemasukan)}", style: const pw.TextStyle(fontSize: 14)),
                    pw.Text("Total Pengeluaran: ${CurrencyFormatter.format(totalPengeluaran)}", style: const pw.TextStyle(fontSize: 14)),
                    pw.Divider(),
                    pw.Text(
                      "LABA BERSIH     : ${CurrencyFormatter.format(labaBersih)}", 
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: labaBersih >= 0 ? PdfColors.green800 : PdfColors.red800)
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // 4. Simpan ke Folder Aplikasi Internal
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'CatatKas_Laporan_$timestamp.pdf';
    final file = File('${directory.path}/$filename');
    
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

    // 5. Coba simpan salinan langsung ke folder Download publik Android (jika memungkinkan)
    String? downloadFilePath;
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final downloadFile = File('${downloadDir.path}/$filename');
        await downloadFile.writeAsBytes(pdfBytes);
        downloadFilePath = downloadFile.path;
      }
    } catch (_) {
      // Abaikan jika tidak ada izin folder publik
    }
    
    return PdfExportResult(
      internalPath: file.path,
      downloadPath: downloadFilePath,
    );
  }
}
