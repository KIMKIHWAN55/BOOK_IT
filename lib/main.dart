import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';

import 'features/auth/services/auth_service.dart';
import 'features/auth/views/app_intro_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/home/views/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('ko_KR', null);

  // [수정] 개발(테스트) 중에는 App Check가 에뮬레이터에서 작동하지 않으므로 잠시 꺼둠
  // 나중에 앱 출시할때 주석해제
  /*
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  */

  // 인트로 확인
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  runApp(
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
    // 로그인 상태 실시간 감시 (인증 반응형 라우팅)
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
      home: _getHomeWidget(authState),

      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  // 로그인 상태 및 온보딩 여부에 따라 화면을 결정하는 헬퍼 함수
  Widget _getHomeWidget(AsyncValue<User?> authState) {
    // 앱을 처음 켰다면 무조건 인트로 화면
    if (!onboardingSeen) {
      return const AppIntroScreen();
    }

    // 인트로를 본 적이 있다면 로그인 상태 확인
    return authState.when(
      data: (user) {
        // user 객체가 존재하면 MainScreen, 아니면 LoginScreen
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