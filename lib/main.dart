import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';

import 'features/auth/services/auth_service.dart';
import 'features/auth/views/app_intro_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/home/views/main_screen.dart';

Future<void> main() async {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

// 🚨 [수정] 개발(테스트) 중에는 App Check가 에뮬레이터에서 작동하지 않으므로 잠시 꺼둡니다!
  // (나중에 앱 출시할 때 주석을 해제하시면 됩니다)
  /*
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  */

  // 온보딩(인트로) 확인
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  runApp(
    // Riverpod 상태 관리의 최상위 스코프
    ProviderScope(
      child: BookitApp(onboardingSeen: onboardingSeen),
    ),
  );
}

class BookitApp extends ConsumerWidget {
  final bool onboardingSeen;

  const BookitApp({super.key, required this.onboardingSeen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 핵심: Firebase 로그인 상태 실시간 감시 (인증 반응형 라우팅)
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: '북잇',
      debugShowCheckedModeBanner: false,
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
      // 🌟 상태에 따른 자동 화면 분기 (초기 화면 설정)
      home: _getHomeWidget(authState),

      // 우리가 만든 AppRouter 연결
      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  // 로그인 상태 및 온보딩 여부에 따라 화면을 결정하는 헬퍼 함수
  Widget _getHomeWidget(AsyncValue<User?> authState) {
    // 1. 앱을 처음 켰다면 무조건 인트로 화면
    if (!onboardingSeen) {
      return const AppIntroScreen();
    }

    // 2. 인트로를 본 적이 있다면 로그인 상태 확인
    return authState.when(
      data: (user) {
        // user 객체가 존재하면(로그인 상태) MainScreen, 아니면 LoginScreen
        // 💡 이 로직 덕분에 로그아웃(signOut) 시 자동으로 LoginScreen으로 튕깁니다!
        if (user != null) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('인증 오류 발생: $error')),
      ),
    );
  }
}