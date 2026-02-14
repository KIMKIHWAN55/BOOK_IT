import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';

// 🌟 [필수] authStateProvider와 화면들을 가져옵니다.
import 'features/auth/services/auth_service.dart';
import 'features/auth/views/app_intro_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/home/views/main_screen.dart'; // 🌟 (주의) main_screen 위치가 다르면 경로 맞춰주세요!

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  runApp(
    // 🌟 1. ProviderScope 적용 (완벽합니다!)
    ProviderScope(
      child: BookitApp(onboardingSeen: onboardingSeen),
    ),
  );
}

// 🌟 2. StatelessWidget ➡️ ConsumerWidget 으로 변경!
class BookitApp extends ConsumerWidget {
  final bool onboardingSeen;

  const BookitApp({super.key, required this.onboardingSeen});

  // 🌟 3. build 메서드에 WidgetRef ref 가 추가됩니다.
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 🌟 4. Firebase 로그인 상태를 Riverpod으로 '실시간 감시(구독)' 합니다.
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

      // 🌟 5. initialRoute 대신 home 속성으로 자동 분기 처리!
      home: _getHomeWidget(authState),

      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  // 🌟 6. 상태(AsyncValue)에 따른 완벽한 로딩/에러/화면 전환 처리
  Widget _getHomeWidget(AsyncValue<User?> authState) {
    if (!onboardingSeen) {
      return const AppIntroScreen();
    }

    // Riverpod의 .when()을 쓰면 데이터, 로딩, 에러 3가지를 강제로 다 처리하게 해줘서 앱이 절대 안 뻗습니다.
    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainScreen(); // 로그인 상태면 자동 메인 이동
        } else {
          return const LoginScreen(); // 로그아웃 상태면 자동 로그인 이동
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('인증 오류 발생: $error'))),
    );
  }
}