import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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

    // 2. Muat gambar logo untuk kop surat
    Uint8List? unnesBytes;
    Uint8List? semarangBytes;
    try {
      final unnesData = await rootBundle.load('assets/images/logo_unnes.png');
      unnesBytes = unnesData.buffer.asUint8List();
      final semarangData = await rootBundle.load('assets/images/logo_semarang.png');
      semarangBytes = semarangData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Gagal memuat logo untuk PDF: $e');
    }

    // 3. Offload PDF building & rendering ke background isolate agar UI 100% lancar
    final pdfBytes = await compute(_buildPdfBytesInBackground, _PdfDataPayload(periodLabel, transactions, unnesBytes, semarangBytes));

    // 4. Simpan ke Folder Aplikasi Internal
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final dateTag = "${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}";
    final filename = 'CatatKas_Laporan_$dateTag.pdf';
    final file = File('${directory.path}/$filename');

    await file.writeAsBytes(pdfBytes, flush: true);

    // 5. Salin ke Folder Download Publik Android
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
              padding: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (payload.logoSemarangBytes != null)
                    pw.Image(pw.MemoryImage(payload.logoSemarangBytes!), width: 55, height: 55),
                  
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text("LAPORAN KEUANGAN BUKU KAS", style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                        pw.SizedBox(height: 4),
                        pw.Text("UMKM Desa Manggihan, Kecamatan Getasan", style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey800)),
                        pw.SizedBox(height: 2),
                        pw.Text("Didukung oleh Tim GIAT 16 UNNES Desa Manggihan", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ),

                  if (payload.logoUnnesBytes != null)
                    pw.Image(pw.MemoryImage(payload.logoUnnesBytes!), width: 55, height: 55),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Periode: ${payload.periodLabel}", style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text("Dicetak: ${DateTime.now().toString().split('.')[0]}", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              ]
            ),
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
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            
            pw.SizedBox(height: 20),
            pw.Divider(),
            
            // Ringkasan
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 260,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Total Pemasukan", style: const pw.TextStyle(fontSize: 12)),
                        pw.Text(CurrencyFormatter.format(totalPemasukan), style: const pw.TextStyle(fontSize: 12, color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                      ]
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Total Pengeluaran", style: const pw.TextStyle(fontSize: 12)),
                        pw.Text(CurrencyFormatter.format(totalPengeluaran), style: const pw.TextStyle(fontSize: 12, color: PdfColors.red800, fontWeight: pw.FontWeight.bold)),
                      ]
                    ),
                    pw.Divider(color: PdfColors.grey400),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Saldo Kas Bersih", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(CurrencyFormatter.format(labaBersih), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: labaBersih >= 0 ? PdfColors.green800 : PdfColors.red800)),
                      ]
                    ),
                  ],
                ),
              ),
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
  final Uint8List? logoUnnesBytes;
  final Uint8List? logoSemarangBytes;

  _PdfDataPayload(this.periodLabel, this.transactions, this.logoUnnesBytes, this.logoSemarangBytes);
}
