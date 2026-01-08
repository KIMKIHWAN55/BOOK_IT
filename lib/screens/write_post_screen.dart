import 'package:flutter/material.dart';

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({super.key});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final TextEditingController _contentController = TextEditingController();

  // 🔸 피그마 CSS 기반 Pretendard 스타일 공통 함수
  TextStyle _ptStyle({
    required double size,
    required FontWeight weight,
    Color color = const Color(0xFF000000),
    double? height = 1.4,
    double? spacing,
  }) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing, // CSS의 letter-spacing 수치 직접 반영
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // CSS: background: #FFFFFF
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 38), // AppBar(80px)와 입력창 사이 간격 조정

              // 1. 내용 입력 프레임 (Frame 1000002914)
              Container(
                width: 358,
                height: 435, // CSS: height: 435px
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F5), // CSS: #F1F1F5
                  borderRadius: BorderRadius.circular(20), // CSS: 20px
                ),
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  style: _ptStyle(size: 16, weight: FontWeight.w400, color: const Color(0xFF222222)),
                  decoration: InputDecoration(
                    hintText: "내용을 입력해 주세요.",
                    hintStyle: _ptStyle(
                      size: 16,
                      weight: FontWeight.w400,
                      color: const Color(0xFF222222),
                      spacing: -0.408, // CSS: letter-spacing: -0.408px
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20), // 프레임 간 간격

              // 2. 책 추천 프레임 (Frame 1000002915)
              GestureDetector(
                onTap: () {
                  // 책 추천 로직 연결 가능
                },
                child: Container(
                  width: 358,
                  height: 108, // CSS: height: 108px
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F5), // CSS: #F1F1F5
                    borderRadius: BorderRadius.circular(20), // CSS: 20px
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 256,
                        top: 75,
                        child: Row(
                          children: [
                            Text(
                              "책 추천하기",
                              style: _ptStyle(
                                size: 16,
                                weight: FontWeight.w400,
                                color: const Color(0xFF111111),
                                spacing: -0.8, // CSS: -0.05em (16 * 0.05)
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: Color(0xFF222222),
                            ), // 화살표 아이콘 (rotate -180도 효과)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- 상단 헤더 (Frame 33 + 글쓰기 텍스트) ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        padding: const EdgeInsets.only(left: 16),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "글쓰기",
        style: _ptStyle(
          size: 20,
          weight: FontWeight.w600,
          spacing: -0.5, // CSS: -0.025em (20 * 0.025)
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: Text(
            "완료",
            style: _ptStyle(size: 16, weight: FontWeight.w600, color: const Color(0xFFD45858)),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}