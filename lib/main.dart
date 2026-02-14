import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🌟 [필수] Riverpod 패키지 임포트
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
        // 텍스트 선택 커서 색상 등 세부 설정도 가능
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

      // 🌟 초기 경로 설정 (앱 켤 때 어디로 갈지 결정)
      initialRoute: _getInitialRoute(),

      // 🌟 라우터 연결
      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  // 🌟 첫 시작 페이지 결정 로직
  // (Riverpod을 써도 앱 시작 시점의 단순 분기는 이렇게 함수로 처리해도 깔끔합니다)
  String _getInitialRoute() {
    // 1. 온보딩을 안 봤으면 -> 온보딩 화면
    if (!onboardingSeen) {
      return AppRouter.intro;
    }

    // 2. 온보딩은 봤는데 로그인을 안 했으면 -> 로그인 화면
    // 3. 로그인도 되어 있으면 -> 메인 화면
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AppRouter.main;
    } else {
      return AppRouter.login;
    }
  }
}