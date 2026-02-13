import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppIntroScreen extends StatefulWidget {
  const AppIntroScreen({super.key});

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends State<AppIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. 슬라이드 내용 (PageView)
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildPage1(),
              _buildPage2(),
              _buildPage3(),
            ],
          ),

          // 2. 하단 컨트롤 영역
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => _buildIndicator(index)),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                            duration: const Duration(milliseconds: 300), curve: Curves.ease);
                      } else {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_seen', true);
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD45858),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == 2 ? '로그인 하러 가기' : '다음으로',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_currentPage < 2)
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_seen', true);
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: const Text(
                      '건너 뛰기',
                      style: TextStyle(color: Color(0xFF767676), fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 소개 페이지 1 ---
  Widget _buildPage1() {
    return _buildSlideLayout(
      title: "이제 혼자서만 책을 보지 마세요",
      description: "마법 책의 정령 부기와 함께 책을 읽고\n책에 대한 관심을 가져 보세요!",
      content: SizedBox(
        height: 350,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildBlob(color: const Color(0xFFE7D3F4).withOpacity(0.5), size: 300, isBlur: true),
            _buildBlob(color: const Color(0xFFFF8888), size: 240, hasBorder: true),
            Image.asset('assets/images/소개페이지 1.png', width: 320),
          ],
        ),
      ),
    );
  }

// --- 소개 페이지 2 (피그마 상세 수치 반영) ---
  Widget _buildPage2() {
    return _buildSlideLayout(
      title: "독서 후의 감정을\n다른사람과 공유해 보세요",
      description: "피드를 통하여 다른 사람들의 감정과\n자신의 감정을 공유하고 책을 추천 받아 보세요.",
      content: SizedBox(
        height: 350, // 캐릭터들이 배치될 전체 높이
        child: Stack(
          children: [
            // 1. 왼쪽 큰 핑크 부기 (Figma width: 280px 기준)
            Positioned(
              left: -10, // 살짝 왼쪽으로 치우친 배치
              top: 10,
              child: _buildBoogiGroup(
                blobColor: const Color(0xFFE7D3F4).withOpacity(0.5),
                innerColor: const Color(0xFFFF8888),
                size: 240, // 피그마 수치에 맞춰 크기 확대
                imagePath: 'assets/images/소개페이지2-1.png',
              ),
            ),
            // 2. 오른쪽 작은 노란 부기 (Figma width: 120px 기준)
            Positioned(
              right: 20,
              top: 100, // 핑크 부기와 겹치도록 아래로 내림
              child: _buildBoogiGroup(
                blobColor: const Color(0xFFFFE392).withOpacity(0.5),
                innerColor: const Color(0xFFF7CC4D),
                size: 120, // 피그마 수치 적용
                imagePath: 'assets/images/소개페이지2.png',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 소개 페이지 3 (이미지 경로 전달하도록 수정됨) ---
  Widget _buildPage3() {
    return _buildSlideLayout(
      title: "나의 독서 레벨을 올려 보세요",
      description: "책을 읽고 퀘스트를 완료하면서 레벨을 올리고\n다양한 보상을 받으면서 재미있게 독서를 해보세요.",
      content: SizedBox(
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: _buildBoogiGroup(
                blobColor: const Color(0xFFE7D3F4).withOpacity(0.5),
                innerColor: const Color(0xFFFF8888),
                size: 250,
                imagePath: 'assets/images/소개페이지 3.png', // 🔸 경로 추가
              ),
            ),
            Positioned(
              bottom: 80,
              child: Stack(
                children: [
                  Container(width: 251, height: 15, decoration: BoxDecoration(color: const Color(0xFFFAD1D1), borderRadius: BorderRadius.circular(100))),
                  Container(width: 194, height: 15, decoration: BoxDecoration(color: const Color(0xFFFF8888), borderRadius: BorderRadius.circular(100))),
                ],
              ),
            ),
            const Positioned(
              bottom: 30,
              child: Text("LV UP!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF8888))),
            ),
          ],
        ),
      ),
    );
  }

  // 공통 슬라이드 레이아웃 빌더
  // 공통 슬라이드 레이아웃 빌더 (폰트 스타일 수정)
  Widget _buildSlideLayout({required String title, required String description, required Widget content}) {
    return Column(
      children: [
        const SizedBox(height: 100),
        content,
        const SizedBox(height: 40),

        // --- 제목 스타일 ---
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Pretendard', // 폰트 패밀리 지정
            fontSize: 24,
            fontWeight: FontWeight.w600, // SemiBold
            color: Color(0xFF222222),
            height: 1.4, // line-height: 140%
            letterSpacing: 24 * -0.025, // letter-spacing: -0.025em
          ),
        ),

        const SizedBox(height: 20),

        // --- 설명글 스타일 ---
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w400, // Regular
            color: Color(0xFF767676),
            height: 1.4, // line-height: 140%
            letterSpacing: 14 * -0.025,
          ),
        ),
      ],
    );
  }

  // 🔸 단 하나의 일관된 _buildBoogiGroup 함수 (중복 제거됨)
  Widget _buildBoogiGroup({
    required Color blobColor,
    required Color innerColor,
    required double size,
    required String imagePath,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildBlob(color: blobColor, size: size, isBlur: true),
        _buildBlob(color: innerColor, size: size * 0.8, hasBorder: true),
        Image.asset(imagePath, width: size * 1.1),
      ],
    );
  }

  Widget _buildBlob({required Color color, required double size, bool isBlur = false, bool hasBorder = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: hasBorder ? Border.all(color: Colors.black, width: 2) : null,
        boxShadow: isBlur ? [BoxShadow(color: color, blurRadius: 15)] : null,
      ),
    );
  }

  Widget _buildIndicator(int index) {
    bool isCurrent = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isCurrent ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFFF8888) : const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}