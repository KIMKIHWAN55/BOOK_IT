import 'package:flutter/material.dart';
import 'category_result_screen.dart';

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
              context: context,
              title: "소설",
              items: [
                _CategoryItem("로맨스", "assets/images/로맨스.png"),
                _CategoryItem("무협", "assets/images/무협.png"),
                _CategoryItem("추리", "assets/images/추리.png"),
                _CategoryItem("공포/미스터리", "assets/images/공포.png"), // '공포.png' 연결
                _CategoryItem("SF", "assets/images/sf.png"),
                _CategoryItem("판타지", "assets/images/판타지.png"),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "자기계발",
              items: [
                _CategoryItem("금융/투자", "assets/images/금융 투자.png"), // 띄어쓰기 주의
                _CategoryItem("여행", "assets/images/여행.png"),
                _CategoryItem("인간관계", "assets/images/인간관계.png"),
                _CategoryItem("건강", "assets/images/건강.png"),
                _CategoryItem("교재/수험서", "assets/images/교재.png"),
                _CategoryItem("성공", "assets/images/성공.png"),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "인문/문학",
              items: [
                _CategoryItem("에세이/시", ""), // 해당 이미지 없음 (빈 문자열 유지)
                _CategoryItem("철학", "assets/images/철학.png"),
                _CategoryItem("심리", "assets/images/심리.png"),
                _CategoryItem("동화", "assets/images/동화.png"),
                _CategoryItem("예술", "assets/images/예술.png"),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "정치/사회",
              items: [
                _CategoryItem("한국사", "assets/images/한국사.png"),
                _CategoryItem("세계사", "assets/images/세계사.png"),
                _CategoryItem("종교", ""), // 해당 이미지 없음
                _CategoryItem("정치", "assets/images/정치.png"),
                _CategoryItem("사회", "assets/images/사회.png"),
                _CategoryItem("경제", "assets/images/경제.png"),
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "가정/생활",
              items: [
                _CategoryItem("요리", "assets/images/요리.png"),
                _CategoryItem("육아", "assets/images/육아.png"),
                _CategoryItem("스포츠", "assets/images/스포츠.png"),
                _CategoryItem("취미", "assets/images/낚시.png"), // '낚시.png'를 취미 대표 이미지로 사용
              ],
            ),
            const SizedBox(height: 40),
            _buildCategorySection(
              context: context,
              title: "청소년/어린이",
              items: [
                _CategoryItem("청소년", "assets/images/청소년.png"),
                _CategoryItem("어린이", "assets/images/어린이.png"),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

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
          spacing: 20,
          runSpacing: 24,
          children: items.map((item) => _buildItemWidget(context, item)).toList(),
        ),
      ],
    );
  }

  Widget _buildItemWidget(BuildContext context, _CategoryItem item) {
    return GestureDetector(
      onTap: () {
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
              color: const Color(0xFFF1F1F5), // 배경색 (이미지 투명 배경일 때 대비)
              borderRadius: BorderRadius.circular(15), // 둥근 모서리
              image: item.imagePath.isNotEmpty
                  ? DecorationImage(
                image: AssetImage(item.imagePath),
                fit: BoxFit.cover, // 이미지를 꽉 채움 (필요시 contain으로 변경)
              )
                  : null,
            ),
            // 이미지가 없을 경우 기본 아이콘 표시
            child: item.imagePath.isEmpty
                ? const Icon(Icons.book, color: Colors.grey, size: 24)
                : null,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 60,
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
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

class _CategoryItem {
  final String label;
  final String imagePath;

  _CategoryItem(this.label, this.imagePath);
}