import 'package:flutter/material.dart';

// 🌟 우리가 만든 화면들 Import
import '../../features/auth/views/app_intro_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/signup_screen.dart';
import '../../features/auth/views/find_id_screen.dart';
import '../../features/auth/views/find_pw_screen.dart';
import '../../features/auth/views/verification_screen.dart';
import '../../features/home/views/main_screen.dart'; // 탭바 있는 메인 화면 (나중에 위치 옮길 예정)

class AppRouter {
  // 1. 라우트 이름(경로) 상수화 (오타 방지용)
  static const String intro = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String findId = '/find_id';
  static const String findPw = '/find_pw';
  static const String verification = '/verification';
  static const String main = '/main';

  // 2. 경로에 따라 화면을 매칭해주는 함수
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case intro:
        return MaterialPageRoute(builder: (_) => const AppIntroScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case findId:
        return MaterialPageRoute(builder: (_) => const FindIdScreen());
      case findPw:
        return MaterialPageRoute(builder: (_) => const FindPwScreen());
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());

    // 🌟 데이터(arguments)를 전달받아야 하는 화면 처리
      case verification:
        final args = settings.arguments as Map<String, dynamic>; // 전달받은 맵 데이터
        return MaterialPageRoute(
          builder: (_) => VerificationScreen(
            email: args['email'],
            password: args['password'],
            name: args['name'],
            nickname: args['nickname'],
            phone: args['phone'],
          ),
        );

    // 🌟 등록되지 않은 잘못된 경로로 갔을 때의 예외 처리 화면
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('경로를 찾을 수 없습니다: ${settings.name}')),
          ),
        );
    }
  }
}