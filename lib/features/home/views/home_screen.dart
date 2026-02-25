import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit_app/features/book/views/book_detail_screen.dart';
import 'package:bookit_app/features/home/controllers/home_controller.dart';
import '../../../shared/widgets/custom_network_image.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentRecommendIndex = 0;

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
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,

      appBar: const CustomAppBar(
        isTransparent: true,
        showCart: true,
      ),

      body: homeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildTopRecommendation(homeState.recommendedBooks),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('이번달 베스트 셀러', style: _ptStyle(size: 20, weight: FontWeight.w600)),

                  GestureDetector(
                    onTap: () {
                      // TODO: 나중에 '베스트셀러 전체보기' 전용 화면을 만들면 여기 연결!
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('베스트셀러 전체보기 화면 준비 중입니다.')),
                      );
                    },
                    child: Text('더보기', style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _buildBestSellerList(homeState.bestSellerBooks),
            const SizedBox(height: 10),
            _buildSpecialBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

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
              onPageChanged: (index) {
                setState(() {
                  _currentRecommendIndex = index;
                });
              },
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailScreen(book: books[index]),
                    ),
                  );
                },
                child: _buildPickCard(books[index].imageUrl),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${books.isEmpty ? 0 : _currentRecommendIndex + 1} / ${books.length}',
            style: _ptStyle(size: 16, weight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellerList(List<dynamic> books) {
    if (books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("등록된 베스트셀러가 없습니다.")),
      );
    }
    //3개씩 표현하는로 직
    List<List<dynamic>> pages = [];
    for (int i = 0; i < books.length; i += 3) {
      int end = (i + 3 < books.length) ? i + 3 : books.length;
      pages.add(books.sublist(i, end));
    }

    // 로로 스와이프 가능한 PageView 생성
    return SizedBox(
      height: 390,
      child: PageView.builder(
        controller: PageController(viewportFraction: 1.0),
        itemCount: pages.length,
        itemBuilder: (context, pageIndex) {
          final pageBooks = pages[pageIndex];

          return Column(
            children: pageBooks.map((book) {
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
                  rank: book.rank.toString(),
                  title: book.title.toString(),
                  author: book.author.toString(),
                  imageUrl: book.imageUrl.toString(),
                  rating: book.rating.toString(),
                  reviewCount: book.reviewCount.toString(),
                ),
              );
            }).toList(),
          );
        },
      ),
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
        child: CustomNetworkImage(
          imageUrl: imageUrl,
        ),
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
            child: CustomNetworkImage(
              imageUrl: imageUrl,
              width: 73,
              height: 110,
            ),
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
}