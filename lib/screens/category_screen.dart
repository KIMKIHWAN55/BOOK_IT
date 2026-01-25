import 'package:flutter/material.dart';

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
            _buildCategorySection(
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

  Widget _buildCategorySection({required String title, required List<_CategoryItem> items}) {
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
          spacing: 20, // 가로 간격 (조절 가능)
          runSpacing: 24, // 세로 줄 간격
          children: items.map((item) => _buildItemWidget(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildItemWidget(_CategoryItem item) {
    // 화면 너비에 따라 4열 혹은 5열로 배치하기 위해 너비 계산 (여기서는 고정 크기 사용)
    return Column(
      children: [
        // 이미지 영역 (50x50)
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200], // 이미지 없을 때 회색 배경
            borderRadius: BorderRadius.circular(8),
            // 실제 이미지가 있다면 아래 주석 해제 후 사용
            // image: DecorationImage(image: AssetImage(item.imagePath), fit: BoxFit.cover),
          ),
          child: const Icon(Icons.book, color: Colors.grey, size: 24), // 임시 아이콘
        ),
        const SizedBox(height: 8),
        // 텍스트 영역
        SizedBox(
          width: 60, // 텍스트 줄바꿈 방지용 너비 확보
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
    );
  }
}

// 데이터 모델 클래스
class _CategoryItem {
  final String label;
  final String imagePath; // 이미지 경로용

  _CategoryItem(this.label, this.imagePath);
}