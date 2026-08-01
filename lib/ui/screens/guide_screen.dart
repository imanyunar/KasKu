import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Panduan Penggunaan'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.maroon.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 24.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Pusat Bantuan CatatKas',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Pilih topik di bawah ini untuk mempelajari cara menggunakan aplikasi dengan optimal.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            Text(
              'Topik Panduan',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            SizedBox(height: 12.h),

            _buildFaqItem(
              title: 'Cara Mencatat Cepat (Ketik Bebas)',
              icon: Icons.bolt_rounded,
              iconColor: AppTheme.maroon,
              iconBg: AppTheme.maroon.withValues(alpha: 0.1),
              content: 'Fitur "Ketik Cepat" adalah asisten pintar untuk mencatat transaksi dengan satu kalimat.\n\n'
                  'Contoh Pengetikan:\n'
                  '• "jual beras 1kg 15rb" (Tercatat: Pemasukan, Beras, 1kg, Rp 15.000)\n'
                  '• "pembelian token listrik 100rb" (Tercatat: Pengeluaran, Token Listrik, 1 pcs, Rp 100.000)\n'
                  '• "beli pupuk urea 2 sak 150.000" (Tercatat: Pengeluaran, Pupuk Urea, 2 sak, Rp 150.000)\n\n'
                  'Tips: Gunakan kata "jual", "terima", atau "pendapatan" untuk Pemasukan. Gunakan kata "beli", "bayar", atau "pengeluaran" untuk Pengeluaran. Anda bisa menyingkat ribuan menjadi "rb" dan jutaan menjadi "jt".',
            ),
            
            _buildFaqItem(
              title: 'Melihat & Mencetak Laporan PDF',
              icon: Icons.picture_as_pdf_rounded,
              iconColor: AppTheme.gold,
              iconBg: AppTheme.gold.withValues(alpha: 0.2),
              content: 'Anda dapat mencetak laporan keuangan langsung dari aplikasi ke dalam format PDF:\n\n'
                  '1. Buka menu "Riwayat Transaksi".\n'
                  '2. Gunakan filter di bagian atas layar (Hari Ini, Bulan Ini, atau Pilih Tanggal Manual) untuk menyesuaikan periode laporan.\n'
                  '3. Tekan ikon "PDF" di sudut kanan atas layar.\n'
                  '4. Aplikasi akan membuat laporan lengkap dengan total pemasukan, pengeluaran, dan rincian transaksi.\n'
                  '5. File PDF akan otomatis disimpan ke folder Download dan dapat langsung dibagikan (Share) ke WhatsApp.',
            ),

            _buildFaqItem(
              title: 'Manajemen Katalog Produk',
              icon: Icons.inventory_2_rounded,
              iconColor: AppTheme.green,
              iconBg: AppTheme.greenSoft,
              content: 'Katalog Produk mempermudah Anda saat melakukan pencatatan transaksi secara manual.\n\n'
                  'Anda bisa memasukkan daftar barang dagangan beserta harga dan satuannya di menu "Katalog Produk". Saat Anda mencatat transaksi manual dan mengetikkan huruf awal nama barang, aplikasi akan otomatis memunculkan saran harga dan satuan, sehingga Anda tidak perlu mengetik ulang.',
            ),

            _buildFaqItem(
              title: 'Backup (Amankan) & Restore Data',
              icon: Icons.cloud_done_rounded,
              iconColor: Colors.blue,
              iconBg: Colors.blue.withValues(alpha: 0.1),
              content: 'Agar data catatan keuangan Anda tidak hilang jika HP rusak atau berganti perangkat, lakukan pencadangan berkala:\n\n'
                  '1. Buka ikon "Pengaturan" di pojok kanan atas Halaman Dasbor.\n'
                  '2. Klik "BACKUP KE FOLDER DOWNLOAD". File CSV akan tersimpan di HP Anda.\n'
                  '3. Sangat disarankan untuk membagikan file tersebut (Share) ke WhatsApp Anda sendiri atau ke Google Drive agar aman.\n'
                  '4. Untuk memulihkan data, tekan tombol "RESTORE DARI FILE CSV" dan pilih file backup Anda.',
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String content,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: iconColor, size: 22.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        iconColor: AppTheme.maroon,
        childrenPadding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h, top: 0),
        children: [
          Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
