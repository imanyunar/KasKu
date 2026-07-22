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
    // Memberikan jeda 2 detik untuk efek splash
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;
    
    if (hasSeenOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.maroon,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Logo Unnes.png',
                  width: 80.r,
                  height: 80.r,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 60.sp, color: AppTheme.gold),
                ),
                SizedBox(width: 24.w),
                Image.asset(
                  'assets/images/Logo Semarang.png',
                  width: 80.r,
                  height: 80.r,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: 60.sp, color: AppTheme.gold),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            Text(
              'CATATKAS',
              style: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.gold,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'GIAT 16 UNNES DESA MANGGIHAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 50.h),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
            ),
          ],
        ),
      ),
    );
  }
}
