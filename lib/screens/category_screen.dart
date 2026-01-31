import 'package:flutter/material.dart';
import 'category_result_screen.dart'; // 🌟 [추가] 결과 화면 import

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "카테고리",
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: -0.025,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 [수정] context 전달
            _buildCategorySection(
              context: context,
              title: "소설",
              items: [
                _CategoryItem("로맨스", ""),
                _CategoryItem("무협", ""),
                _CategoryItem("추리", ""),
                _CategoryItem("공포/미스터리", ""),
                _CategoryItem("SF", ""),
                _CategoryItem("판타지", ""),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "자기계발",
              items: [
                _CategoryItem("금융/투자", ""),
                _CategoryItem("여행", ""),
                _CategoryItem("인간관계", ""),
                _CategoryItem("건강", ""),
                _CategoryItem("교재/수험서", ""),
                _CategoryItem("성공", ""),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "인문/문학",
              items: [
                _CategoryItem("에세이/시", ""),
                _CategoryItem("철학", ""),
                _CategoryItem("심리", ""),
                _CategoryItem("동화", ""),
                _CategoryItem("예술", ""),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "정치/사회",
              items: [
                _CategoryItem("한국사", ""),
                _CategoryItem("세계사", ""),
                _CategoryItem("종교", ""),
                _CategoryItem("정치", ""),
                _CategoryItem("사회", ""),
                _CategoryItem("경제", ""),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "가정/생활",
              items: [
                _CategoryItem("요리", ""),
                _CategoryItem("육아", ""),
                _CategoryItem("스포츠", ""),
                _CategoryItem("취미", ""),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "청소년/어린이",
              items: [
                _CategoryItem("청소년", ""),
                _CategoryItem("어린이", ""),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 🌟 [수정] context 인자 추가
  Widget _buildCategorySection({required BuildContext context, required String title, required List<_CategoryItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
            letterSpacing: -0.025,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 20, // 가로 간격
          runSpacing: 24, // 세로 줄 간격
          children: items.map((item) => _buildItemWidget(context, item)).toList(), // 🌟 context 전달
        ),
      ],
    );
  }

  // 🌟 [수정] context 인자 추가 및 클릭 이벤트 연결
  Widget _buildItemWidget(BuildContext context, _CategoryItem item) {
    return GestureDetector(
      onTap: () {
        // 🌟 클릭 시 해당 카테고리 결과 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryResultScreen(category: item.label),
          ),
        );
      },
      child: Column(
        children: [
          // 이미지 영역
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200], // 이미지 없을 때 회색 배경
              borderRadius: BorderRadius.circular(8),
            // 🌟 [수정] 이미지가 있을 때만 이미지를 보여주도록 설정
              image: item.imagePath.isNotEmpty
                  ? DecorationImage(
                image: AssetImage(item.imagePath), // 👈 경로에 있는 이미지 로드
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: const Icon(Icons.book, color: Colors.grey, size: 24), // 임시 아이콘
          ),
          const SizedBox(height: 8),
          // 텍스트 영역
          SizedBox(
            width: 60,
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
                letterSpacing: -0.025,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 데이터 모델 클래스
class _CategoryItem {
  final String label;
  final String imagePath; // 이미지 경로용

  _CategoryItem(this.label, this.imagePath);
}