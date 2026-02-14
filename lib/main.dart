import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // 🌟 [필수] 패키지 임포트
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🌟 [추가] App Check 활성화 (안드로이드 전용)
  // iOS 설정은 아예 뺐으므로 아이폰에서는 App Check가 동작하지 않음 (오류도 안 남)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // 2. SharedPreferences 초기화 (온보딩 여부 확인)
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  runApp(
    // 🌟 [핵심] 앱 전체를 ProviderScope로 감싸야 Riverpod이 작동합니다.
    ProviderScope(
      child: BookitApp(onboardingSeen: onboardingSeen),
    ),
  );
}

class BookitApp extends StatelessWidget {
  final bool onboardingSeen;

  const BookitApp({super.key, required this.onboardingSeen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '북잇',
      debugShowCheckedModeBanner: false,

      // 🌟 테마 설정
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ),

      // 🌟 초기 경로 설정
      initialRoute: _getInitialRoute(),

      // 🌟 라우터 연결
      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  // 🌟 첫 시작 페이지 결정 로직
  String _getInitialRoute() {
    if (!onboardingSeen) {
      return AppRouter.intro;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AppRouter.main;
    } else {
      return AppRouter.login;
    }
  }
}