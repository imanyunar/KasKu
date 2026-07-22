import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:catatkas/core/theme.dart';
import 'package:catatkas/ui/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Selamat Datang di CatatKas!",
      "description": "Aplikasi pencatatan modern khusus warung desa. Pencatatan keuangan kini semudah mengirim pesan.",
      "icon": "👋",
    },
    {
      "title": "Ketik Cepat ala SMS",
      "description": "Cukup ketik 'jual bawang 1kg 15rb' dan aplikasi otomatis mencatatnya dengan rapi. Anda juga bisa memilih menu dari daftar produk.",
      "icon": "⚡",
    },
    {
      "title": "Data Aman Tanpa Internet",
      "description": "Semua pembukuan tersimpan aman di dalam HP Anda 100% offline. Bebas hambatan walau tak ada sinyal.",
      "icon": "🔒",
    },
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.all(40.0.r),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _onboardingData[index]['icon']!,
                          style: TextStyle(fontSize: 100.sp),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          _onboardingData[index]['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.maroon,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          _onboardingData[index]['description']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Indikator halaman (dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  height: 10,
                  width: _currentPage == index ? 30 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppTheme.gold : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
            // Tombol navigasi
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w, vertical: 20.0.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Menggunakan style default dari global theme
                  onPressed: () {
                    if (_currentPage == _onboardingData.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _onboardingData.length - 1
                        ? "Mulai Gunakan Aplikasi"
                        : "Lanjut",
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
