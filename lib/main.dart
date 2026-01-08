import 'package:bookit_app/screens/cart_screen.dart';
import 'package:bookit_app/screens/chat_screen.dart';
import 'package:bookit_app/screens/home_screen.dart';
import 'package:bookit_app/screens/intro_chat_screen.dart';
import 'package:bookit_app/screens/login_screen.dart';
import 'package:bookit_app/screens/signup_screen.dart';
import 'package:bookit_app/screens/app_intro_screen.dart'; // 인트로 화면
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔸 추가됨

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔸 1. 인트로를 본 적이 있는지 휴대폰 메모리에서 확인
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  // 🔸 2. 확인된 값을 앱에 전달
  runApp(BookitApp(onboardingSeen: onboardingSeen));
}

class BookitApp extends StatelessWidget {
  final bool onboardingSeen; // 🔸 추가됨

  const BookitApp({super.key, required this.onboardingSeen}); // 🔸 생성자 수정

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '북잇',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
          ),
        ),
      ),

      // 🔸 3. 첫 화면 결정 로직 수정
      home: _getHomeWidget(),

      routes: {
        '/intro': (context) => const AppIntroScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/intro_chat': (context) => const IntroChatScreen(),
        '/chat': (context) => const ChatScreen(),
        '/cart': (context) => const CartScreen(),
      },
    );
  }

  // 🔸 첫 화면을 결정하는 별도의 함수
  Widget _getHomeWidget() {
    // 1순위: 인트로를 안 봤다면 무조건 인트로 화면으로
    if (!onboardingSeen) {
      return const AppIntroScreen();
    }

    // 2순위: 인트로를 봤다면 로그인 상태에 따라 홈 또는 로그인 화면으로
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}