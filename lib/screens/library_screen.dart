import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 디자인 기준 사이즈
    const double designWidth = 390.0;
    const double designHeight = 920.0;

    return Scaffold(
      backgroundColor: const Color(0xFFC58152), // 전체 배경색
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: designWidth,
            height: designHeight,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(color: Color(0xFFC58152)),
            child: Stack(
              children: [
                // 1. 나무 질감 배경 (Rectangle 32917)
                Positioned(
                  top: 98,
                  left: 0,
                  child: Container(
                    width: 390,
                    height: 685,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        // 이미지가 없을 경우를 대비해 갈색 계열 처리
                        image: AssetImage('assets/images/wood_bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // 2. 선반 이미지들 (image 37, 38 등 - 그림자/선반 효과)
                _buildShelfShadow(top: 45, left: -15),
                _buildShelfShadow(top: 283, left: -17),
                _buildShelfShadow(top: 503, left: -17),

                // 3. 상단 바 (Frame 33 + Status Bar)
                _buildAppBar(context),

                // 4. 책 목록 (명세된 좌표값 적용)
                // 첫 번째 줄
                _buildBook(top: 193, left: (390 / 2) - (79 / 2) - 115.5, label: "Sci-Fi"),
                _buildBook(top: 193, left: (390 / 2) - (79 / 2) + 0.5, label: "Romance"),
                _buildBook(top: 193, left: (390 / 2) - (79 / 2) + 116.5, label: "Drama"),

                // 두 번째 줄
                _buildBook(top: 430, left: (390 / 2) - (79 / 2) - 115.5, label: "Cat Illustration"),
                _buildBook(top: 430, left: (390 / 2) - (79 / 2) + 0.5, label: "Blue Romance"),

                // 5. 하단 네비게이션 바 (navi)
                Positioned(
                  bottom: 0,
                  child: _buildBottomNav(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// _buildAppBar 메서드 수정 (context 인자 추가)
  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: 390,
      height: 80,
      padding: const EdgeInsets.only(top: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ▼▼▼ 뒤로가기 아이콘 부분 수정 ▼▼▼
          Positioned(
            left: 8, // 위치 조절
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 24),
              onPressed: () {
                Navigator.pop(context); // 현재 화면을 닫고 이전 화면으로 이동
              },
            ),
          ),
          // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
          const Text(
            '내 서재',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Positioned(
            right: 16,
            child: Stack(
              children: [
                const Icon(Icons.notifications_none, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA4335), // 빨간 알림 점
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 책 위젯
  Widget _buildBook({required double top, required double left, required String label}) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 79,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(6, 8),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // 선반 그림자/이미지 레이어
  Widget _buildShelfShadow({required double top, required double left}) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 415,
        height: 415,
        // 실제로는 선반 이미지가 들어가야 하는 자리입니다.
        child: Opacity(
          opacity: 0.1,
          child: Image.network('https://via.placeholder.com/415x415?text=Shelf+Shadow'),
        ),
      ),
    );
  }

  // 하단 네비게이션 바
  Widget _buildBottomNav() {
    return Container(
      width: 390,
      height: 76,
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(Icons.home_outlined, false),
              _navIcon(Icons.search, false),
              _navIcon(Icons.edit_note, false),
              _navIcon(Icons.menu_book, true), // 서재 아이콘 활성화
              _navIcon(Icons.person_outline, false),
            ],
          ),
          const Spacer(),
          // 홈 인디케이터 영역
          Container(
            width: 128,
            height: 5,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isActive) {
    return Container(
      width: 74,
      height: 44,
      child: Icon(
        icon,
        color: isActive ? Colors.black : const Color(0xFFB8B8B8),
        size: 24,
      ),
    );
  }
}