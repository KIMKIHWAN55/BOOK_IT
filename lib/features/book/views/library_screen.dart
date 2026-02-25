import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/custom_network_image.dart';
import '../models/book_model.dart';
import '../controllers/library_controller.dart';
import '../../board/views/write_review_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  //  책 위치 좌표 정의)
  final List<Map<String, double>> _bookPositions = [
    {'top': 193, 'left': (390 / 2) - (79 / 2) - 115.5}, // 1번 책
    {'top': 193, 'left': (390 / 2) - (79 / 2) + 0.5},   // 2번 책
    {'top': 193, 'left': (390 / 2) - (79 / 2) + 116.5}, // 3번 책
    {'top': 430, 'left': (390 / 2) - (79 / 2) - 115.5}, // 4번 책
    {'top': 430, 'left': (390 / 2) - (79 / 2) + 0.5},   // 5번 책
  ];

  // 🔹 책 클릭 시: 독서 기록 및 리뷰 팝업
  void _showBookOptionDialog(BookModel book, QueryDocumentSnapshot purchaseDoc) {
    final data = purchaseDoc.data() as Map<String, dynamic>?;
    int currentPage = (data != null && data.containsKey('currentPage')) ? data['currentPage'] : 0;
    final TextEditingController pageController = TextEditingController(text: currentPage.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("현재 $currentPage 페이지까지 읽으셨습니다."),
              const SizedBox(height: 20),
              TextField(
                controller: pageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '수정할 페이지 입력',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final newPage = int.tryParse(pageController.text.trim());
                  if (newPage != null) {
                    try {
                      await ref.read(libraryControllerProvider).updateCurrentPage(book.id, newPage);
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("업데이트 실패: $e")),
                        );
                      }
                    }
                  }
                },
                child: const Text("독서 기록 수정"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD45858)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WriteReviewScreen(book: book)),
                  );
                },
                child: const Text("리뷰 작성하러 가기", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchasedBooksAsync = ref.watch(purchasedBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFC58152),
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 390,
            height: 920,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(color: Color(0xFFC58152)),
            child: Stack(
              children: [
                //  배경 / 선반 이미지
                Positioned(
                  top: 98, left: 0,
                  child: Container(
                    width: 390, height: 685,
                    decoration: const BoxDecoration(
                      image: DecorationImage(image: AssetImage('assets/images/wood.png'), fit: BoxFit.cover),
                    ),
                  ),
                ),
                _buildShelfShadow(top: 45, left: -15),
                _buildShelfShadow(top: 283, left: -17),
                _buildShelfShadow(top: 503, left: -17),

                // 상단 바
                _buildAppBar(context),

                // 서재에 꽂힌 책들
                purchasedBooksAsync.when(
                  data: (snapshot) {
                    final docs = snapshot.docs;
                    if (docs.isEmpty) return const SizedBox();

                    return Stack(
                      children: List.generate(docs.length, (index) {
                        if (index >= _bookPositions.length) return const SizedBox(); // 5권까지만 표시

                        var data = docs[index].data() as Map<String, dynamic>;

                        BookModel book = BookModel(
                          id: data['id'] ?? docs[index].id,
                          title: data['title'] ?? '제목 없음',
                          imageUrl: data['imageUrl'] ?? '',
                          author: data['author'] ?? '작자 미상',
                          rank: 0,
                          rating: '',
                          reviewCount: '',
                          category: '',
                          tags: [],
                          description: '',
                        );

                        return Positioned(
                          top: _bookPositions[index]['top'],
                          left: _bookPositions[index]['left'],
                          child: GestureDetector(
                            onTap: () => _showBookOptionDialog(book, docs[index]),
                            child: Container(
                              width: 79,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: const Offset(6, 8),
                                      blurRadius: 8
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: CustomNetworkImage(
                                  imageUrl: book.imageUrl,
                                  width: 79.0,
                                  height: 120.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (error, stack) => Center(child: Text("오류: $error", style: const TextStyle(color: Colors.white))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: 390,
      height: 80,
      padding: const EdgeInsets.only(top: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            '내 서재',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Positioned(
            right: 16,
            child: Stack(
              children: [
                const Icon(Icons.notifications_none, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA4335), // 빨간 알림 점
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfShadow({required double top, required double left}) {
    return Positioned(
      top: top,
      left: left,
      child: SizedBox(
        width: 415,
        height: 415,
        child: Opacity(
          opacity: 0.1,
          child: CustomNetworkImage(
            imageUrl: 'https://via.placeholder.com/415x415?text=Shelf+Shadow',
          ),
        ),
      ),
    );
  }
}