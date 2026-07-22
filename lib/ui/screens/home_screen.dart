import 'dart:ui';
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Dekorasi Modern (Glow effect)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.maroon.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (App Bar Custom)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang,',
                            style: TextStyle(fontSize: 16.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Warga Manggihan',
                            style: TextStyle(fontSize: 24.sp, color: AppTheme.textDark, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.settings_outlined, color: AppTheme.textDark),
                          onPressed: () async {
                            await Navigator.push(context, _createRoute(const SettingsScreen()));
                            _loadSaldo();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Main Balance Card (Fintech Style)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(32.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B0000), Color(0xFF4A0000)], // Deep maroon to blackish red
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B0000).withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(Icons.account_balance_wallet, color: AppTheme.gold, size: 24),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Saldo Hari Ini',
                                style: TextStyle(
                                  fontSize: 18.sp, 
                                  fontWeight: FontWeight.w500, 
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          if (_isLoading)
                            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold))
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
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _formatCurrency(_saldoHariIni),
                                  key: ValueKey<double>(_saldoHariIni),
                                  style: TextStyle(
                                    color: _saldoHariIni >= 0 ? Colors.white : const Color(0xFFFF8A80),
                                    fontSize: 44.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Quick Actions (E-Wallet Style)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        icon: Icons.assessment_rounded, 
                        label: 'Riwayat & Laporan', 
                        onTap: () async {
                          await Navigator.push(context, _createRoute(const HistoryScreen()));
                          _loadSaldo();
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.inventory_2_rounded, 
                        label: 'Produk', 
                        onTap: () async {
                          await Navigator.push(context, _createRoute(const ProductScreen()));
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                
                // Big FAB (Catat Transaksi)
                Padding(
                  padding: EdgeInsets.all(24.0.r),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuart,
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - opacity)),
                          child: child,
                        ),
                      );
                    },
                    child: ElevatedButton(
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
                          Icon(Icons.add_circle_rounded, size: 28),
                          SizedBox(width: 12.w),
                          Text('CATAT TRANSAKSI', style: TextStyle(fontSize: 20.sp)),
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

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, size: 28, color: AppTheme.maroon),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
