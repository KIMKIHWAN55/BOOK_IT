import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookit_app/features/book/models/book_model.dart';
import 'package:bookit_app/features/board/views/write_review_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // 🔹 책 위치 좌표 정의 (Shelf 디자인에 맞춤)
  final List<Map<String, double>> _bookPositions = [
    {'top': 193, 'left': (390 / 2) - (79 / 2) - 115.5}, // 1번 책
    {'top': 193, 'left': (390 / 2) - (79 / 2) + 0.5},   // 2번 책
    {'top': 193, 'left': (390 / 2) - (79 / 2) + 116.5}, // 3번 책
    {'top': 430, 'left': (390 / 2) - (79 / 2) - 115.5}, // 4번 책
    {'top': 430, 'left': (390 / 2) - (79 / 2) + 0.5},   // 5번 책
  ];

  // 🔹 책 클릭 시: 독서 기록 및 리뷰 팝업
  void _showBookOptionDialog(BookModel book, DocumentSnapshot purchaseDoc) {
    int currentPage = purchaseDoc['currentPage'] ?? 0;

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
              ElevatedButton(
                onPressed: () {
                  // TODO: 페이지 업데이트 로직 (Dialog 띄워서 입력받기 등)
                  // purchaseDoc.reference.update({'currentPage': newValue});
                  Navigator.pop(context);
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
    if (user == null) return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));

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
                // 1. 배경 & 선반 이미지 (기존 코드 유지)
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

                // 2. 상단 바
                _buildAppBar(context),

                // 3. 🌟 [수정] 구매한 책 리스트 스트림 연결
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('purchased_books')
                      .orderBy('purchasedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final docs = snapshot.data!.docs;

                    return Stack(
                      children: List.generate(docs.length, (index) {
                        if (index >= _bookPositions.length) return const SizedBox(); // 5권까지만 표시 (자리 부족)

                        var data = docs[index];
                        // BookModel로 변환 (purchased_books에 저장된 필드 사용)
                        BookModel book = BookModel(
                          id: data['id'],
                          title: data['title'],
                          imageUrl: data['imageUrl'],
                          // 나머지 필드는 기본값 또는 저장된 값 사용
                          rank: '', author: data['author'], rating: '', reviewCount: '', category: '',
                        );

                        return Positioned(
                          top: _bookPositions[index]['top'],
                          left: _bookPositions[index]['left'],
                          child: GestureDetector(
                            onTap: () => _showBookOptionDialog(book, data),
                            child: Container(
                              width: 79,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.25), offset: const Offset(6, 8), blurRadius: 8),
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(book.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // _buildAppBar 메서드 수정 (context 인자 추가)
  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: 390,
      height: 80,
      padding: const EdgeInsets.only(top: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔸 메인 탭이므로 뒤로가기 버튼 삭제
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

  // 책 위젯
  Widget _buildBook({required double top, required double left, required String label}) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 79,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(6, 8),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // 선반 그림자/이미지 레이어
  Widget _buildShelfShadow({required double top, required double left}) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 415,
        height: 415,
        child: Opacity(
          opacity: 0.1,
          child: Image.network('https://via.placeholder.com/415x415?text=Shelf+Shadow'),
        ),
      ),
    );
  }
}