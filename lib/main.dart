import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 로그인 확인용
import 'firebase_options.dart';
import 'core/router/app_router.dart'; // 🌟 라우터 불러오기
import 'core/constants/app_colors.dart'; // 🌟 테마 적용을 위해 추가

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  runApp(BookitApp(onboardingSeen: onboardingSeen));
}

class BookitApp extends StatelessWidget {
  final bool onboardingSeen;

  const BookitApp({super.key, required this.onboardingSeen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '북잇',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard', // 🌟 기본 폰트 설정
        scaffoldBackgroundColor: AppColors.background, // 🌟 공통 배경색 적용
        primaryColor: AppColors.primary,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ),

      // 🌟 핵심 1: 첫 시작 경로 설정
      // onboardingSeen 값에 따라 시작점을 다르게 줍니다.
      initialRoute: _getInitialRoute(),

      // 🌟 핵심 2: 중앙 집중식 라우터 연결
      // 이제 아래 한 줄로 모든 페이지 이동이 관리됩니다.
      onGenerateRoute: AppRouter.generateRoute,

      // 🌟 핵심 3: 로그인 상태 감지 (최상위 빌더)
      // 앱이 켜진 후 로그인 상태가 변할 때 자동으로 화면을 전환해주고 싶다면
      // 아래와 같이 StreamBuilder를 활용한 처리가 가능합니다.
      builder: (context, child) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // 여기에 전역적인 상태 처리(로딩 등)를 추가할 수 있습니다.
            return child!;
          },
        );
      },
    );
  }

  // 🌟 첫 시작 페이지를 결정하는 로직
  String _getInitialRoute() {
    if (!onboardingSeen) {
      return AppRouter.intro;
    }

    // 이미 온보딩을 봤다면, 로그인 여부에 따라 분기
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AppRouter.main;
    } else {
      return AppRouter.login;
    }
  }
}