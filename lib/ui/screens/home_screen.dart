import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';
import 'package:catatkas/ui/screens/add_transaction_screen.dart';
import 'package:catatkas/ui/screens/history_screen.dart';
import 'package:catatkas/ui/screens/product_screen.dart';
import 'package:catatkas/ui/screens/settings_screen.dart';
import 'package:catatkas/core/database/database_helper.dart';
import 'package:catatkas/core/utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _saldoHariIni = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaldo();
  }

  Future<void> _loadSaldo() async {
    setState(() => _isLoading = true);
    final saldo = await DatabaseHelper.instance.getDailySaldo();
    setState(() {
      _saldoHariIni = saldo;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    return '${amount < 0 ? "- " : "+ "}${CurrencyFormatter.format(amount)}';
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
      transitionDuration: const Duration(milliseconds: 400),
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
          Positioned(
            top: 240.h,
            left: -120.w,
            child: Container(
              width: 280.r,
              height: 280.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Profil & Tanggal
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48.r,
                            height: 48.r,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppTheme.maroon.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'KM',
                                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kas UMKM • $dateFormatted',
                                style: TextStyle(fontSize: 13.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Desa Manggihan',
                                style: TextStyle(fontSize: 20.sp, color: AppTheme.textDark, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.tune_rounded, color: AppTheme.maroon, size: 22.sp),
                          tooltip: 'Pengaturan',
                          onPressed: () async {
                            await Navigator.push(context, _createRoute(const SettingsScreen()));
                            _loadSaldo();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // 2. Executive Balance Card (Fintech Card Style)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.maroon.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
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
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded, color: AppTheme.gold, size: 16.sp),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Saldo Kas Hari Ini',
                                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh_rounded, color: Colors.white70, size: 20.sp),
                              onPressed: _loadSaldo,
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        if (_isLoading)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold)),
                          )
                        else
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: SizedBox(
                              height: 52.h,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _formatCurrency(_saldoHariIni),
                                  key: ValueKey<double>(_saldoHariIni),
                                  style: TextStyle(
                                    color: _saldoHariIni >= 0 ? Colors.white : const Color(0xFFFF8A80),
                                    fontSize: 42.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 28.h),

                // 3. Quick Action Cards (Modern Fintech Style)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Utama',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMenuTile(
                              title: 'Riwayat & Laporan',
                              subtitle: 'Cetak PDF & Filter',
                              icon: Icons.assessment_rounded,
                              iconColor: AppTheme.maroon,
                              iconBg: AppTheme.maroon.withOpacity(0.1),
                              onTap: () async {
                                await Navigator.push(context, _createRoute(const HistoryScreen()));
                                _loadSaldo();
                              },
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: _buildMenuTile(
                              title: 'Katalog Produk',
                              subtitle: 'Daftar Barang',
                              icon: Icons.inventory_2_rounded,
                              iconColor: AppTheme.gold,
                              iconBg: AppTheme.gold.withOpacity(0.15),
                              onTap: () async {
                                await Navigator.push(context, _createRoute(const ProductScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                
                // 4. Primary Floating Action Button ("Catat Transaksi")
                Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.maroon.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      onPressed: () async {
                        final bool? shouldRefresh = await Navigator.push(
                          context,
                          _createRoute(const AddTransactionScreen()),
                        );
                        if (shouldRefresh == true) {
                          _loadSaldo();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_rounded, size: 22.sp, color: Colors.white),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'CATAT TRANSAKSI',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
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
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(icon, size: 24.sp, color: iconColor),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: Colors.grey.shade400),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
