import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:catatkas/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const String _versionUrl = 
      'https://raw.githubusercontent.com/imanyunar/catatkas-web/main/public/version.json';
  static const String currentVersion = '1.0.0';

  static Future<void> checkUpdate(BuildContext context) async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'] as String?;
        final downloadUrl = data['download_url'] as String? ?? 
            'https://imanyunar.github.io/catatkas-web/CatatKas_UMKM.apk';
        final releaseNotes = data['release_notes'] as String? ?? 'Pembaruan aplikasi terbaru.';

        if (latestVersion != null && _isNewerVersion(latestVersion, currentVersion)) {
          if (!context.mounted) return;
          _showUpdateDialog(context, latestVersion, downloadUrl, releaseNotes);
        }
      }
    } catch (_) {
      // Jika offline, timeout, atau error, abaikan tanpa mengganggu pengguna
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    try {
      List<int> latestParts = latest.split('.').map((e) => int.parse(e)).toList();
      List<int> currentParts = current.split('.').map((e) => int.parse(e)).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return false;
    }
  }

  static void _showUpdateDialog(
      BuildContext context, String version, String url, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.system_update_rounded, color: AppTheme.maroon, size: 28.sp),
            SizedBox(width: 10.w),
            Text('Update Tersedia!', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi $version telah rilis untuk CatatKas UMKM.',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            SizedBox(height: 8.h),
            Text(notes, style: TextStyle(fontSize: 13.sp, color: AppTheme.textMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('NANTI SAJA', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.maroon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(url);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: Text('PERBARUI', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
