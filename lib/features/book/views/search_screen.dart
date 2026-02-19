import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_model.dart';
import '../controllers/search_controller.dart';
import 'book_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  // 🔹 피그마 텍스트 스타일 공통 함수
  TextStyle _ptStyle({
    required double size,
    required FontWeight weight,
    Color color = const Color(0xFF222222),
  }) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.025 * size,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('검색', style: _ptStyle(size: 20, weight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- 1. 검색창 ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '찾고 싶은 책, 작가, 장르를 입력해주세요',
                  hintStyle: _ptStyle(
                      size: 14,
                      weight: FontWeight.w400,
                      color: const Color(0xFF767676)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.search, color: Color(0xFF767676), size: 24),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- 2. 검색 결과 목록 ---
          Expanded(
            child: _searchText.isEmpty
                ? _buildEmptyState()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  // 검색 결과 위젯 (Riverpod 상태 구독)
  Widget _buildSearchResults() {
    final booksAsync = ref.watch(allBooksProvider);

    return booksAsync.when(
      data: (allBooks) {
        // 앱 내부에서 'contains'를 사용하여 중간 글자까지 검색되도록 필터링합니다.
        final books = allBooks.where((book) {
          final titleLower = book.title.toLowerCase();
          final searchLower = _searchText.toLowerCase();
          final authorLower = book.author.toLowerCase();

          // 제목 또는 작가 이름에 검색어가 '포함'되어 있으면 결과에 추가
          return titleLower.contains(searchLower) || authorLower.contains(searchLower);
        }).toList();

        if (books.isEmpty) {
          return const Center(child: Text("검색 결과가 없습니다."));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: book),
                  ),
                );
              },
              child: _buildSearchResultItem(book),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(child: Text("오류가 발생했습니다.")),
    );
  }

  // --- 3. 검색 결과 아이템 ---
  Widget _buildSearchResultItem(BookModel book) {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F1F5), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 책 표지
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              book.imageUrl,
              width: 73,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 73,
                height: 110,
                color: Colors.grey[200],
                child: const Icon(Icons.book, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 제목 및 저자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  book.title,
                  style: _ptStyle(size: 16, weight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  book.author,
                  style: _ptStyle(
                      size: 14,
                      weight: FontWeight.w400,
                      color: const Color(0xFF777777)),
                ),
              ],
            ),
          ),
          // 더보기 버튼
          Text('더보기',
              style: _ptStyle(
                  size: 14,
                  weight: FontWeight.w400,
                  color: const Color(0xFF767676))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "검색어를 입력하여 책을 찾아보세요",
        style: _ptStyle(
            size: 14, weight: FontWeight.w400, color: const Color(0xFF767676)),
      ),
    );
  }
}