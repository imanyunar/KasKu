import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';
import 'package:catatkas/core/utils/backup_helper.dart';
import 'package:catatkas/ui/screens/product_screen.dart';
import 'package:catatkas/ui/screens/about_screen.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Pengaturan & Backup'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 24),
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
              description: 'Simpan salinan (backup) catatan kas ke HP Anda. File akan tersimpan di folder Download agar mudah dipindahkan ke HP baru.',
              icon: Icons.cloud_download_rounded,
              buttonLabel: 'BACKUP KE FOLDER DOWNLOAD',
              buttonColor: AppTheme.maroon,
              buttonTextColor: Colors.white,
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sedang membuat file... Tunggu sebentar.', style: TextStyle(fontSize: 16.sp))),
                  );
                  
                  final path = await BackupHelper.exportToCsv();
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('SUKSES! Data tersimpan di:\n$path', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  String errorMsg = e.toString();
                  if (errorMsg.contains('DatabaseException')) {
                    errorMsg = 'Terjadi kesalahan saat memproses data.';
                  } else if (errorMsg.contains('Exception:')) {
                    errorMsg = errorMsg.split('Exception:').last.trim();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
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
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['csv'],
                  );

                  if (result != null && result.files.single.path != null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sedang mengimpor data...', style: TextStyle(fontSize: 16.sp))),
                    );

                    final count = await BackupHelper.importFromCsv(result.files.single.path!);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('SUKSES! Berhasil mengembalikan $count transaksi.', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
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
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                  color: AppTheme.maroon.withOpacity(0.1),
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
