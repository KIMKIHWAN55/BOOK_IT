import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookit_app/features/book/models/book_model.dart';
import 'package:bookit_app/features/book/views/book_detail_screen.dart';
import 'package:bookit_app/features/book/views/category_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🔸 [삭제] _selectedIndex 변수 제거 (MainScreen에서 관리)

  // 🔸 피그마 Pretendard 스타일 공통 적용 함수
  TextStyle _ptStyle({
    required double size,
    required FontWeight weight,
    Color color = const Color(0xFF222222),
    double height = 1.4,
  }) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * -0.025,
    );
  }

  // 🔸 [삭제] _onItemTapped 함수 제거 (MainScreen에서 처리)

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // 1. 왼쪽: 카테고리 메뉴 버튼 (leading)
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), // 배경이 어두우므로 흰색 아이콘 사용
          onPressed: () {
            // 카테고리 화면으로 이동 (파일이 만들어져 있어야 함)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoryScreen()),
            );
          },
        ),

        // 2. 배경 설정 (투명)
        backgroundColor: Colors.transparent,
        elevation: 0,

        // 3. 오른쪽: 검색, 장바구니, 알림 버튼 (actions) -> 기존 코드 유지!
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/search'); // 검색 화면 이동
              },
              icon: const Icon(Icons.search, color: Colors.white)
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white)),
// 🌟 [수정] 장바구니 개수 실시간 연동
              if (user != null)
                Positioned(
                  top: 10, right: 8,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('cart')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox(); // 데이터 없으면 숨김
                      }
                      return _buildBadge(snapshot.data!.docs.length.toString());
                    },
                  ),
                ),
            ],
          ),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: Colors.white)
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 추천 Pick 섹션
            _buildTopRecommendation(),

            const SizedBox(height: 32),

            // 2. 베스트 셀러 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('이번달 베스트 셀러', style: _ptStyle(size: 20, weight: FontWeight.w600)),
                  Text('더보기',
                      style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 3. 베스트 셀러 리스트
// 3. 베스트 셀러 리스트 영역
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .orderBy('rank') // 순위별로 정렬해서 가져옴
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // 1위~9위 사이의 책만 필터링하는 로직
                final bestSellerBooks = docs.map((doc) {
                  return BookModel.fromFirestore(doc);
                }).where((book) {
                  // rank를 숫자로 변환해서 1~9 사이인지 확인
                  int? r = int.tryParse(book.rank);
                  return r != null && r >= 1 && r <= 9;
                }).toList();

                if (bestSellerBooks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("등록된 베스트셀러가 없습니다.")),
                  );
                }

                return Column(
                  children: bestSellerBooks.map((book) {
                    // 👇 책을 클릭하면 상세페이지로 이동하는 기능 추가
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(book: book),
                          ),
                        );
                      },
                      // 기존에 만든 아이템 위젯 재사용
                      child: _buildBestsellerItem(
                        rank: book.rank,
                        title: book.title,
                        author: book.author,
                        imageUrl: book.imageUrl,
                        rating: book.rating,
                        reviewCount: book.reviewCount,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 10),

            // 4. 하단 특별 기획 배너
            _buildSpecialBanner(),

            const SizedBox(height: 40),
          ],
        ),
      ),
      // 🔸 [삭제] bottomNavigationBar 속성 전체 삭제
    );
  }

  // --- 위젯 빌더 함수들은 기존과 동일 (생략 가능하나 구조 확인을 위해 유지) ---
  Widget _buildTopRecommendation() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .where('category', isEqualTo: 'recommend')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final books = docs.map((doc) => BookModel.fromFirestore(doc)).toList();

        return Container(
          width: double.infinity,
          height: 420,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0x99999999), Color(0xB2222222)],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 100),
              Text('이번주 추천 Pick!', style: _ptStyle(size: 22, weight: FontWeight.w500, color: Colors.white)),
              const SizedBox(height: 30),
              SizedBox(
                height: 200,
                child: books.isEmpty
                    ? const Center(child: Text("추천 도서가 없습니다.", style: TextStyle(color: Colors.white)))
                    : PageView.builder(
                  itemCount: books.length,
                  controller: PageController(viewportFraction: 0.6),
                  itemBuilder: (context, index) => _buildPickCard(books[index].imageUrl),
                ),
              ),
              const SizedBox(height: 20),
              Text('${books.isEmpty ? 0 : 1} / ${books.length}', style: _ptStyle(size: 16, weight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickCard(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(-10, 15))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(imageUrl, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBestsellerItem({
    required String rank,
    required String title,
    required String author,
    required String imageUrl,
    required String rating,
    required String reviewCount
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(imageUrl, width: 73, height: 110, fit: BoxFit.cover)),
          const SizedBox(width: 27),
          Text(rank, style: _ptStyle(size: 20, weight: FontWeight.w600)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: _ptStyle(size: 16, weight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(author,
                    style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF777777))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
                    const SizedBox(width: 4),
                    Text(rating,
                        style: _ptStyle(size: 12, weight: FontWeight.w600, color: const Color(0xFFFBBC05))),
                    Text(' ($reviewCount)',
                        style: _ptStyle(size: 12, weight: FontWeight.w400, color: const Color(0xFF777777))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialBanner() {
    return Container(
      width: 326,
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: const Color(0xFF21212F), borderRadius: BorderRadius.circular(32)),
      child: Stack(
        children: [
          Positioned(
            left: 32,
            top: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('여러분들을 위해\n지금 준비 했어요!',
                    style: _ptStyle(size: 20, weight: FontWeight.w600, color: Colors.white, height: 1.2)),
                const SizedBox(height: 12),
                Text('다신 오지 않는 특별한 기획', style: _ptStyle(size: 14, weight: FontWeight.w400, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String count) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Color(0xFFEA4335), shape: BoxShape.circle),
      child: Text(count,
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}