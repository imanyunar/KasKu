import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tentang CatatKas UMKM'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32.h),
            Image.asset('assets/images/app_logo.png', width: 96.r, height: 96.r, fit: BoxFit.contain),
            SizedBox(height: 16.h),
            Text(
              'CatatKas UMKM',
              style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              'Versi 1.0.0',
              style: TextStyle(fontSize: 18.sp, color: Colors.black54),
            ),
            SizedBox(height: 32.h),
            const Divider(thickness: 2),
            SizedBox(height: 32.h),
            Text(
              'Aplikasi pembukuan keuangan sederhana berbasis Android untuk pelaku UMKM. '
              'Berjalan 100% offline tanpa perlu koneksi internet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(height: 32.h),
            Text(
              'Dikembangkan Oleh:',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo_unnes.png', width: 64, height: 64),
                SizedBox(width: 24.w),
                Image.asset('assets/images/logo_semarang.png', width: 64, height: 64),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Developer: Iman Yunar Noviadhi\nGIAT 16 UNNES DESA MANGGIHAN (2026)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.sp, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 48.h),
            Text(
              'Hak Cipta © 2026',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
