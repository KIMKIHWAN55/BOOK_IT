import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🌟 Riverpod 필수 import
import 'package:bookit_app/features/book/views/book_detail_screen.dart';
import 'package:bookit_app/features/book/views/category_screen.dart';
import 'package:bookit_app/features/home/controllers/home_controller.dart'; // homeProvider가 정의된 파일

// 🌟 [변경 1] ConsumerStatefulWidget 상속
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// 🌟 [변경 2] ConsumerState 사용
class _HomeScreenState extends ConsumerState<HomeScreen> {

  // 🔸 스타일 함수 (기존 유지)
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

  @override
  Widget build(BuildContext context) {
    // 🌟 [변경 3] ref.watch로 상태 구독 (데이터가 변하면 알아서 화면 갱신)
    // 이제 _controller 변수 대신 homeState를 사용합니다.
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,

      // 🔹 AppBar 분리
      appBar: _buildAppBar(context),

      // 🔹 로딩 상태 체크 (homeState.isLoading 사용)
      body: homeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // 1. 추천 Pick 섹션 (데이터 전달)
            _buildTopRecommendation(homeState.recommendedBooks),

            const SizedBox(height: 32),

            // 2. 베스트 셀러 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('이번달 베스트 셀러', style: _ptStyle(size: 20, weight: FontWeight.w600)),
                  Text('더보기', style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 3. 베스트 셀러 리스트 (데이터 전달)
            _buildBestSellerList(homeState.bestSellerBooks),

            const SizedBox(height: 10),

            // 4. 하단 특별 기획 배너
            _buildSpecialBanner(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🔹 AppBar 위젯
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // 🌟 [변경 4] 장바구니 개수 구독 (StreamProvider 사용)
    // AsyncValue 타입으로 들어옵니다 (loading, data, error 상태 포함)
    final cartCountAsync = ref.watch(cartCountProvider);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CategoryScreen()),
          );
        },
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/search');
          },
          icon: const Icon(Icons.search, color: Colors.white),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            ),
            // 🌟 [변경 5] AsyncValue 처리 (.when 사용)
            // 데이터가 로딩 중이거나 에러일 때는 숨기고, 데이터가 있을 때만 뱃지 표시
            cartCountAsync.when(
              data: (count) => count > 0
                  ? Positioned(
                  top: 10,
                  right: 8,
                  child: _buildBadge(count.toString())
              )
                  : const SizedBox(),
              loading: () => const SizedBox(),
              error: (err, stack) => const SizedBox(),
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none, color: Colors.white),
        ),
      ],
    );
  }

  // 🔹 추천 도서 위젯 (데이터를 파라미터로 받음)
  Widget _buildTopRecommendation(List<dynamic> books) {
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
  }

  // 🔹 베스트셀러 리스트 위젯 (데이터를 파라미터로 받음)
  Widget _buildBestSellerList(List<dynamic> books) {
    if (books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("등록된 베스트셀러가 없습니다.")),
      );
    }

    return Column(
      children: books.map((book) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            );
          },
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
  }

  // --- 기존 UI 컴포넌트 (변경 없음) ---

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
    required String reviewCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(imageUrl, width: 73, height: 110, fit: BoxFit.cover),
          ),
          const SizedBox(width: 27),
          Text(rank, style: _ptStyle(size: 20, weight: FontWeight.w600)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _ptStyle(size: 16, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(author, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF777777))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
                    const SizedBox(width: 4),
                    Text(rating, style: _ptStyle(size: 12, weight: FontWeight.w600, color: const Color(0xFFFBBC05))),
                    Text(' ($reviewCount)', style: _ptStyle(size: 12, weight: FontWeight.w400, color: const Color(0xFF777777))),
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
                Text('여러분들을 위해\n지금 준비 했어요!', style: _ptStyle(size: 20, weight: FontWeight.w600, color: Colors.white, height: 1.2)),
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
      child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}