import 'dart:io';
import 'package:flutter/foundation.dart';
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
  /// Generate dan simpan Laporan PDF secara asinkron tanpa membekukan (lag) UI
  static Future<PdfExportResult> generateReportPdf(String periodLabel, DateTime start, DateTime end) async {
    // 1. Ambil data dari SQLite (Async I/O)
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

    // 2. Offload PDF building & rendering ke background isolate agar UI 100% lancar
    final pdfBytes = await compute(_buildPdfBytesInBackground, _PdfDataPayload(periodLabel, transactions));

    // 3. Simpan ke Folder Aplikasi Internal
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final dateTag = "${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}";
    final filename = 'CatatKas_Laporan_$dateTag.pdf';
    final file = File('${directory.path}/$filename');

    await file.writeAsBytes(pdfBytes, flush: true);

    // 4. Salin ke Folder Download Publik Android
    String? downloadFilePath;
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final downloadFile = File('${downloadDir.path}/$filename');
        await downloadFile.writeAsBytes(pdfBytes, flush: true);
        downloadFilePath = downloadFile.path;
      }
    } catch (_) {
      // Background copy fallback
    }

    return PdfExportResult(
      internalPath: file.path,
      downloadPath: downloadFilePath,
    );
  }

  /// Fungsi rendering PDF murni yang berjalan di background isolate (compute)
  static Future<Uint8List> _buildPdfBytesInBackground(_PdfDataPayload payload) async {
    double totalPemasukan = 0;
    double totalPengeluaran = 0;
    for (var item in payload.transactions) {
      if (item.isJual) {
        totalPemasukan += item.price;
      } else {
        totalPengeluaran += item.price;
      }
    }
    double labaBersih = totalPemasukan - totalPengeluaran;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Laporan Keuangan CatatKas UMKM", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Desa Manggihan", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text("Periode: ${payload.periodLabel}", style: const pw.TextStyle(fontSize: 13)),
            pw.Text("Tanggal Cetak: ${DateTime.now().toString().split('.')[0]}", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            pw.SizedBox(height: 16),
            
            // Tabel Transaksi
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Tanggal', 'Jenis', 'Nama Barang', 'Qty', 'Harga'],
              data: List<List<dynamic>>.generate(
                payload.transactions.length,
                (index) {
                  final item = payload.transactions[index];
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
            
            pw.SizedBox(height: 20),
            pw.Divider(),
            
            // Ringkasan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Total Pemasukan : ${CurrencyFormatter.format(totalPemasukan)}", style: const pw.TextStyle(fontSize: 13)),
                    pw.Text("Total Pengeluaran: ${CurrencyFormatter.format(totalPengeluaran)}", style: const pw.TextStyle(fontSize: 13)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "UNTUNG / RUGI    : ${CurrencyFormatter.format(labaBersih)}", 
                      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: labaBersih >= 0 ? PdfColors.green800 : PdfColors.red800)
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}

class _PdfDataPayload {
  final String periodLabel;
  final List<TransactionItem> transactions;

  _PdfDataPayload(this.periodLabel, this.transactions);
}
