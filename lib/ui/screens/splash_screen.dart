import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:catatkas/core/theme.dart';
import 'package:catatkas/ui/screens/home_screen.dart';
import 'package:catatkas/ui/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;
    
    if (hasSeenOnboarding) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B1527), Color(0xFF4A000D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Decorative Circle Glows
            Positioned(
              top: -80.h,
              right: -80.w,
              child: Container(
                width: 260.r,
                height: 260.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -100.h,
              left: -100.w,
              child: Container(
                width: 300.r,
                height: 300.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.maroonLight.withOpacity(0.2),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Glassmorphic Badge Containers for Logos
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/Logo Unnes.png',
                          width: 72.r,
                          height: 72.r,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 54.sp, color: AppTheme.gold),
                        ),
                        SizedBox(width: 20.w),
                        Container(width: 1.w, height: 50.h, color: Colors.white24),
                        SizedBox(width: 20.w),
                        Image.asset(
                          'assets/images/Logo Semarang.png',
                          width: 72.r,
                          height: 72.r,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: 54.sp, color: AppTheme.gold),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 36.h),

                  Text(
                    'CATATKAS',
                    style: TextStyle(
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.gold,
                      letterSpacing: 3.0,
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'GIAT 16 UNNES • DESA MANGGIHAN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: EdgeInsets.only(bottom: 40.h),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 28.r,
                          height: 28.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Solusi Kas UMKM Modern',
                          style: TextStyle(fontSize: 13.sp, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
