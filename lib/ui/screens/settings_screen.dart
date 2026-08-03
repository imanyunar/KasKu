import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:catatkas/core/utils/backup_helper.dart';
import 'package:catatkas/ui/screens/product_screen.dart';
import 'package:catatkas/ui/screens/about_screen.dart';
import 'package:catatkas/ui/screens/guide_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pengaturan & Backup'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Penyimpanan Data Aman',
              description: 'Simpan salinan (backup) catatan kas ke HP Anda. File dapat dibagikan langsung ke WhatsApp atau Google Drive agar tetap aman.',
              icon: Icons.cloud_download_rounded,
              buttonLabel: 'BACKUP KE FOLDER DOWNLOAD',
              buttonColor: AppTheme.maroon,
              buttonTextColor: Colors.white,
              onPressed: () async {
                final sm = ScaffoldMessenger.of(context);
                try {
                  sm.showSnackBar(
                    SnackBar(content: Text('Sedang membuat file... Tunggu sebentar.', style: TextStyle(fontSize: 16.sp))),
                  );
                  
                  final path = await BackupHelper.exportToCsv();
                  
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('lastBackupDate', DateTime.now().millisecondsSinceEpoch);
                  
                  if (!context.mounted) return;
                  
                  sm.showSnackBar(
                    SnackBar(
                      content: Text('SUKSES! Data berhasil di-backup.', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  // Menampilkan pop-up Share bawaan HP
                  Share.shareXFiles([XFile(path)], text: 'Backup Data CatatKas UMKM');
                } catch (e) {
                  if (!context.mounted) return;
                  String errorMsg = e.toString();
                  if (errorMsg.contains('DatabaseException')) {
                    errorMsg = 'Terjadi kesalahan saat memproses data.';
                  } else if (errorMsg.contains('Exception:')) {
                    errorMsg = errorMsg.split('Exception:').last.trim();
                  } else if (errorMsg.contains('PlatformException')) {
                    errorMsg = 'Akses ditolak atau terjadi kesalahan pada sistem Android Anda.';
                  }
                  sm.showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $errorMsg', style: TextStyle(fontSize: 16.sp)),
                      backgroundColor: AppTheme.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
            ),
            
            SizedBox(height: 24.h),
            
            _buildSection(
              title: 'Kembalikan Data (Restore)',
              description: 'Baca catatan kas dari file CSV yang pernah Anda backup sebelumnya.',
              icon: Icons.cloud_upload_rounded,
              buttonLabel: 'RESTORE DARI FILE CSV',
              buttonColor: Colors.white,
              buttonTextColor: AppTheme.textDark,
              isOutline: true,
              onPressed: () async {
                try {
                  // Konfirmasi sebelum restore untuk mencegah duplikasi data
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                      title: Text('Restore Data?', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      content: Text(
                        'Data dari file CSV akan DITAMBAHKAN ke data yang sudah ada. Jika Anda pernah restore file ini sebelumnya, data bisa terduplikat.\n\nLanjutkan?',
                        style: TextStyle(fontSize: 14.sp, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('BATAL', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.maroon,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('YA, RESTORE', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;

                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['csv'],
                  );

                  if (result != null && result.files.single.path != null) {
                    if (!context.mounted) return;
                    final sm = ScaffoldMessenger.of(context);
                    sm.showSnackBar(
                      SnackBar(content: Text('Sedang mengimpor data...', style: TextStyle(fontSize: 16.sp))),
                    );

                    final count = await BackupHelper.importFromCsv(result.files.single.path!);

                    if (!context.mounted) return;
                    sm.showSnackBar(
                      SnackBar(
                        content: Text('SUKSES! Berhasil mengembalikan $count data.', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        backgroundColor: AppTheme.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  String errorMsg = e.toString();
                  if (errorMsg.contains('DatabaseException')) {
                    errorMsg = 'Terjadi kesalahan sistem saat memproses data.';
                  } else if (errorMsg.contains('Exception:')) {
                    errorMsg = errorMsg.split('Exception:').last.trim();
                  } else if (errorMsg.contains('PlatformException')) {
                    errorMsg = 'Akses ditolak atau file CSV tidak didukung sistem Android Anda.';
                  }
                  final smErr = ScaffoldMessenger.of(context);
                  smErr.showSnackBar(
                    SnackBar(
                      content: Text('Gagal Restore: $errorMsg', style: TextStyle(fontSize: 16.sp)),
                      backgroundColor: AppTheme.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
            ),
            
            SizedBox(height: 24.h),
            
            _buildSection(
              title: 'Manajemen Produk',
              description: 'Kelola daftar barang langganan Anda agar pencatatan transaksi lebih cepat.',
              icon: Icons.inventory_2_rounded,
              buttonLabel: 'DAFTAR BARANG',
              buttonColor: AppTheme.maroon,
              buttonTextColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductScreen()),
                );
              },
            ),
            
            SizedBox(height: 24.h),
            
            _buildSection(
              title: 'Panduan Penggunaan',
              description: 'Pelajari fitur Ketik Cepat, Cetak Laporan PDF, hingga fitur lainnya.',
              icon: Icons.menu_book_rounded,
              buttonLabel: 'BUKA PANDUAN',
              buttonColor: AppTheme.gold,
              buttonTextColor: AppTheme.textDark,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GuideScreen()),
                );
              },
            ),

            SizedBox(height: 24.h),
            
            _buildSection(
              title: 'Bantuan & Dukungan',
              description: 'Ada kendala atau pertanyaan? Hubungi kami langsung melalui WhatsApp.',
              icon: Icons.chat_bubble_outline_rounded,
              buttonLabel: 'HUBUNGI WHATSAPP',
              buttonColor: const Color(0xFF25D366), // Warna hijau khas WhatsApp
              buttonTextColor: Colors.white,
              onPressed: () async {
                // Ganti dengan nomor WhatsApp Anda yang benar
                final Uri url = Uri.parse('https://wa.me/6287873861108?text=Halo%20Admin%20CatatKas,%20saya%20butuh%20bantuan');
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal membuka WhatsApp')),
                    );
                  }
                }
              },
            ),

            SizedBox(height: 24.h),
            
            _buildSection(
              title: 'Informasi Aplikasi',
              description: 'Versi, pembuat aplikasi, dan info selengkapnya mengenai CatatKas.',
              icon: Icons.info_outline_rounded,
              buttonLabel: 'TENTANG CATATKAS',
              buttonColor: AppTheme.textDark,
              buttonTextColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required IconData icon,
    required String buttonLabel,
    required Color buttonColor,
    required Color buttonTextColor,
    required VoidCallback onPressed,
    bool isOutline = false,
  }) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppTheme.maroon.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.maroon, size: 24),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            description,
            style: TextStyle(fontSize: 14.sp, color: AppTheme.textMuted, height: 1.5),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: isOutline ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonLabel,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
