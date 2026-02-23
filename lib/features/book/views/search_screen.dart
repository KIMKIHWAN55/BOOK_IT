import 'dart:async'; // 🌟 디바운스(Timer)를 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/custom_network_image.dart';

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

  // 🌟 [추가 1] 디바운스를 위한 타이머 변수
  Timer? _debounce;

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
    _debounce?.cancel(); // 🌟 화면이 꺼질 때 타이머도 끄기
    _searchController.dispose();
    super.dispose();
  }

  // 🌟 [추가 2] 타자 칠 때마다 즉시 검색하지 않고 0.3초 대기하는 함수
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchText = query;
      });
    });
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
                onChanged: _onSearchChanged, // 🌟 디바운스 함수 연결
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
                  // 🌟 [추가 3] 글자가 있을 때만 나타나는 원클릭 지우기 버튼
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged(''); // 검색어 초기화
                      FocusScope.of(context).unfocus(); // 키보드 내리기
                    },
                  )
                      : null,
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

  Widget _buildSearchResults() {
    final booksAsync = ref.watch(allBooksProvider);

    return booksAsync.when(
      data: (allBooks) {
        final searchLower = _searchText.toLowerCase();

        final books = allBooks.where((book) {
          final titleLower = book.title.toLowerCase();
          final authorLower = book.author.toLowerCase();

          // 🌟 [추가 4] 책의 태그(장르) 배열도 하나의 문자열로 합쳐서 검색 대상에 포함!
          final tagsLower = book.tags.join(" ").toLowerCase();
          final categoryLower = book.category.toLowerCase();

          return titleLower.contains(searchLower) ||
              authorLower.contains(searchLower) ||
              tagsLower.contains(searchLower) ||
              categoryLower.contains(searchLower);
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
                // 키보드 내리고 이동
                FocusScope.of(context).unfocus();
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
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CustomNetworkImage(
              imageUrl: book.imageUrl,
              width: 73,
              height: 110,
            ),
          ),
          const SizedBox(width: 20),
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