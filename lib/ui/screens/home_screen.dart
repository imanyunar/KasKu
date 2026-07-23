import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';
import 'package:catatkas/ui/screens/add_transaction_screen.dart';
import 'package:catatkas/ui/screens/history_screen.dart';
import 'package:catatkas/ui/screens/product_screen.dart';
import 'package:catatkas/ui/screens/settings_screen.dart';
import 'package:catatkas/core/database/database_helper.dart';
import 'package:catatkas/core/utils/currency_formatter.dart';
import 'package:catatkas/core/utils/pdf_helper.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _saldoHariIni = 0;
  double _totalPemasukanBulanIni = 0;
  double _totalPengeluaranBulanIni = 0;
  double _labaBersihBulanIni = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final saldoTotal = await DatabaseHelper.instance.getTotalSaldo();
    final summary = await DatabaseHelper.instance.getReportSummary(startOfMonth, endOfMonth);

    setState(() {
      _saldoHariIni = saldoTotal;
      _totalPemasukanBulanIni = summary['pemasukan'] ?? 0;
      _totalPengeluaranBulanIni = summary['pengeluaran'] ?? 0;
      _labaBersihBulanIni = summary['untung'] ?? 0;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }

  Future<void> _exportPdfDashboard() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month, now.day, 23, 59, 59);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.maroon),
              SizedBox(height: 14.h),
              Text('Membuat PDF Laporan...', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await PdfHelper.generateReportPdf('BULAN INI', startOfMonth, endOfMonth);

      if (!mounted) return;
      Navigator.pop(context);

      await OpenFilex.open(result.internalPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          backgroundColor: AppTheme.green,
          duration: const Duration(milliseconds: 2500),
          content: Text('PDF Laporan Bulan Ini Berhasil Dibuat',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          action: SnackBarAction(
            label: 'BAGIKAN',
            textColor: Colors.white,
            onPressed: () {
              try {
                Share.shareXFiles([XFile(result.internalPath)], text: 'Laporan Keuangan CatatKas Bulan Ini');
              } catch (_) {}
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak ada transaksi untuk dicetak PDF.', style: TextStyle(fontSize: 14.sp)),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Route<T> _createRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatted = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient Glow Backdrop
          Positioned(
            top: -120.h,
            right: -80.w,
            child: Container(
              width: 320.r,
              height: 320.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.maroon.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Profil & Pengaturan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppTheme.maroon.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'KM',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CatatKas UMKM • $dateFormatted',
                                style: TextStyle(fontSize: 12.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Desa Manggihan',
                                style: TextStyle(fontSize: 18.sp, color: AppTheme.textDark, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.tune_rounded, color: AppTheme.maroon, size: 20.sp),
                          tooltip: 'Pengaturan',
                          onPressed: () async {
                            await Navigator.push(context, _createRoute(const SettingsScreen()));
                            _loadDashboardData();
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // 2. Executive Balance Card (Saldo Hari Ini)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.maroon.withOpacity(0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded, color: AppTheme.gold, size: 14.sp),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Total Saldo Kas Saat Ini',
                                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh_rounded, color: Colors.white70, size: 18.sp),
                              onPressed: _loadDashboardData,
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        if (_isLoading)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.h),
                            child: const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold)),
                          )
                        else
                          SizedBox(
                            height: 44.h,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_saldoHariIni < 0 ? "- " : "+ "}${_formatCurrency(_saldoHariIni)}',
                                style: TextStyle(
                                  color: _saldoHariIni >= 0 ? Colors.white : const Color(0xFFFF8A80),
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 3. Ringkasan Laporan Keuangan (Ringkas & Terintegrasi di Dashboard)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ringkasan Laporan Bulan Ini',
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            InkWell(
                              onTap: _exportPdfDashboard,
                              borderRadius: BorderRadius.circular(10.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: AppTheme.maroon.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf_rounded, color: AppTheme.maroon, size: 16.sp),
                                    SizedBox(width: 4.w),
                                    Text('PDF', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppTheme.maroon)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: AppTheme.greenSoft,
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_upward_rounded, color: AppTheme.green, size: 14.sp),
                                        SizedBox(width: 4.w),
                                        Text('Pemasukan', style: TextStyle(fontSize: 11.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _formatCurrency(_totalPemasukanBulanIni),
                                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: AppTheme.redSoft,
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_downward_rounded, color: AppTheme.red, size: 14.sp),
                                        SizedBox(width: 4.w),
                                        Text('Pengeluaran', style: TextStyle(fontSize: 11.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _formatCurrency(_totalPengeluaranBulanIni),
                                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // 4. Navigasi Menu (Riwayat & Katalog)
                  Text(
                    'Menu Utama',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuCard(
                          title: 'Riwayat Transaksi',
                          subtitle: 'Daftar & Edit Catatan',
                          icon: Icons.history_rounded,
                          iconColor: AppTheme.maroon,
                          iconBg: AppTheme.maroon.withOpacity(0.08),
                          onTap: () async {
                            await Navigator.push(context, _createRoute(const HistoryScreen()));
                            _loadDashboardData();
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMenuCard(
                          title: 'Katalog Produk',
                          subtitle: 'Daftar Barang Usaha',
                          icon: Icons.inventory_2_rounded,
                          iconColor: AppTheme.gold,
                          iconBg: AppTheme.gold.withOpacity(0.12),
                          onTap: () async {
                            await Navigator.push(context, _createRoute(const ProductScreen()));
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // 5. Tombol Catat Transaksi
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.maroon.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: () async {
                        final bool? shouldRefresh = await Navigator.push(
                          context,
                          _createRoute(const AddTransactionScreen()),
                        );
                        if (shouldRefresh == true) {
                          _loadDashboardData();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_rounded, size: 22.sp, color: Colors.white),
                          SizedBox(width: 10.w),
                          Text(
                            'CATAT TRANSAKSI',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(icon, size: 22.sp, color: iconColor),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: Colors.grey.shade400),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
