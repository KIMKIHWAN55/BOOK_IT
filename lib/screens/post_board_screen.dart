import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookit_app/screens/write_post_screen.dart';
import 'package:bookit_app/screens/book_detail_screen.dart'; // ★ 사용자님 상세 페이지
import 'package:bookit_app/models/book_model.dart'; // ★ 데이터 모델

class PostBoardScreen extends StatefulWidget {
  const PostBoardScreen({super.key});

  @override
  State<PostBoardScreen> createState() => _PostBoardScreenState();
}

class _PostBoardScreenState extends State<PostBoardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // 🔸 피그마 스타일 헬퍼 함수
  TextStyle _ptStyle({required double size, required FontWeight weight, Color color = const Color(0xFF222222)}) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.black, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WritePostScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 상단 탭바
          Container(
            color: Colors.white,
            height: 60,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFD45858),
              labelColor: const Color(0xFFD45858),
              unselectedLabelColor: Colors.black,
              labelStyle: _ptStyle(size: 17, weight: FontWeight.w400),
              tabs: const [
                Tab(text: "최근 소식"),
                Tab(text: "좋아요"),
                Tab(text: "나의 글"),
              ],
            ),
          ),
          // 메인 컨텐츠 영역
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecentFeed(), // 여기가 핵심 피드
                const Center(child: Text("좋아요 탭 준비중")),
                const Center(child: Text("나의 글 탭 준비중")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Firestore 실시간 피드
  Widget _buildRecentFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("등록된 글이 없습니다."));
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            return _PostCard(doc: docs[index]);
          },
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// 🔹 개별 게시글 카드 위젯 (분리됨)
// ----------------------------------------------------------------------
class _PostCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const _PostCard({required this.doc});

  // ❤️ 좋아요 토글 함수 (중복 방지 로직 포함)
  Future<void> _toggleLike(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    final uid = user.uid;
    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> likedBy = data['likedBy'] ?? [];

    if (likedBy.contains(uid)) {
      // 이미 좋아요 -> 취소
      await doc.reference.update({
        'likeCount': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      // 안 누름 -> 좋아요
      await doc.reference.update({
        'likeCount': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // 💬 댓글 바텀시트
  void _showCommentSheet(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("댓글 남기기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: doc.reference.collection('comments').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: Text("첫 댓글을 남겨보세요!"));
                      final comments = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final cData = comments[index].data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(cData['content'] ?? ''),
                            subtitle: Text(
                              (cData['createdAt'] as Timestamp?)?.toDate().toString().substring(0, 16) ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(hintText: "댓글 입력...", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD45858)),
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          doc.reference.collection('comments').add({
                            'content': commentController.text,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          doc.reference.update({'commentCount': FieldValue.increment(1)});
                          commentController.clear();
                        }
                      },
                      child: const Text("등록"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;

    // 데이터 추출
    final List<dynamic> likedBy = data['likedBy'] ?? [];
    final bool isLiked = user != null && likedBy.contains(user.uid);
    final List<String> tags = List<String>.from(data['tags'] ?? []);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 유저 프로필 헤더
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDBDBDB),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['nickname'] ?? '익명', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const Text("방금 전", style: TextStyle(fontSize: 12, color: Color(0xFF767676))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 글 내용
          Text(data['bookTitle'] ?? '제목 없음', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // 임시로 책 제목을 글 제목처럼 사용
          const SizedBox(height: 12),
          Text(data['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFF222222))),

          // 3. 해시태그 (있을 경우만 표시)
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: tags.map((t) => Text(t, style: const TextStyle(color: Color(0xFF196DF8), fontSize: 14))).toList(),
            ),
          ],

          const SizedBox(height: 20),

          // 4. ★ 책 카드 (클릭 시 상세 이동)
          GestureDetector(
            onTap: () {
              // 🚀 Firestore 데이터를 BookModel로 변환하여 전달
              final bookModel = BookModel(
                title: data['bookTitle'] ?? '제목 없음',
                author: data['bookAuthor'] ?? '저자 미상',
                imageUrl: data['bookImageUrl'] ?? 'https://i.ibb.co/b6yFp7G/book1.jpg', // 기본 이미지
                description: data['content'] ?? '', // 게시글 내용을 상세페이지 설명으로 사용
                tags: tags,
                price: 15000,          // (임시값) DB에 가격이 없어서 고정값 사용
                discountedPrice: 13500, // (임시값)
                discountRate: 10,       // (임시값)
                reviewCount: 12,        // (임시값)
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(book: bookModel),
                ),
              );
            },
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF1F1F5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          data['bookImageUrl'] ?? '',
                          width: 73, height: 110, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 73, color: Colors.grey[300]),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(data['bookTitle'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            Text(data['bookAuthor'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF777777))),
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
                                SizedBox(width: 2),
                                Text("4.8 (12)", style: TextStyle(fontSize: 12, color: Color(0xFF777777))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Positioned(
                    right: 10, bottom: 10,
                    child: Row(
                      children: [
                        Text("책 보러가기", style: TextStyle(fontSize: 14, color: Color(0xFF111111))),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 5. 좋아요 & 댓글 버튼
          Row(
            children: [
              // 좋아요
              GestureDetector(
                onTap: () => _toggleLike(context),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 24,
                      color: isLiked ? const Color(0xFFD45858) : const Color(0xFF222222),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${data['likeCount'] ?? 0}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isLiked ? const Color(0xFFD45858) : const Color(0xFF222222),
                        fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              // 댓글
              GestureDetector(
                onTap: () => _showCommentSheet(context),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 24, color: Color(0xFF222222)),
                    const SizedBox(width: 4),
                    Text("${data['commentCount'] ?? 0}", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}