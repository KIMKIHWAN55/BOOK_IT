import 'package:flutter/material.dart';
import 'package:bookit_app/screens/login_screen.dart'; // 로그인 화면 import

class SignupCompleteScreen extends StatelessWidget {
  const SignupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 100, color: Color(0xFFD45858)),
            const SizedBox(height: 20),
            const Text("회원가입 완료!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("북잇의 회원이 되신 것을 환영합니다.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // 로그인 화면으로 이동 (모든 스택 제거)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD45858),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text("로그인하러 가기", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}