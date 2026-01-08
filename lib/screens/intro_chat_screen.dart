import 'package:flutter/material.dart';
import 'dart:math' as math; // 도형 회전을 위해 math 라이브러리 import

class IntroChatScreen extends StatelessWidget {
  const IntroChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 크기를 가져오기 위해 MediaQuery 사용
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFE8DFFF), // 시안의 연보라색 배경
      // 1. AppBar (상단 바)
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              icon: const Icon(Icons.shopping_cart_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
        backgroundColor: Colors.transparent, // 배경을 투명하게
        foregroundColor: Colors.black,
        elevation: 0, // 그림자 제거
      ),
      // 2. Body (메인 콘텐츠)
      // Stack을 사용하여 배경 도형과 캐릭터, 버튼 등을 겹겹이 쌓습니다.
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 배경에 있는 컬러 도형들 (Blob)
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFFDD561).withOpacity(0.8), // 노란색
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF6DA7FE).withOpacity(0.8), // 파란색
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 중앙 콘텐츠 (캐릭터, 책, 말풍선)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none, // Stack 영역을 벗어나는 위젯도 보이게 함
                  children: [
                    // =========================================================
                    // ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
                    // 부기 캐릭터 이미지 파일 경로만 변경
                    Image.asset(
                      'assets/images/boogi_final.png', // <-- 새로 추가한 이미지 파일 경로
                      width: size.width * 0.8, // 화면 너비의 80% 크기
                    ),
                    // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
                    // =========================================================

                    // 말풍선 위치 조정 (새 이미지에 맞게)
                    Positioned(
                      top: 20, // 캐릭터 이미지에 맞게 위치 조정
                      left: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Text(
                          '안녕! 난 부기야\n만나서 반가워',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.1), // 화면 높이에 비례하여 간격 조정
              ],
            ),
          ),

          // "부기와 대화 하러 가기" 버튼
          Positioned(
            bottom: 100, // 하단 네비게이션 바 위쪽
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chat');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F30E2), // 진한 보라색
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: const Text(
                '부기와 대화 하러 가기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

