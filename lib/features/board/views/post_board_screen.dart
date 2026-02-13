import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookit_app/features/board/views/write_post_screen.dart';
import 'package:bookit_app/features/book/views/book_detail_screen.dart'; // ★ 사용자님의 상세 페이지 import
import 'package:bookit_app/features/book/models/book_model.dart'; // ★ BookModel이 정의된 파일 import

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

  // 🔸 Pretendard 스타일 헬퍼 함수
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      // 상단 앱바
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
          // 탭바 (최근 소식 / 좋아요 / 나의 글)
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
            // 1. 최근 소식 (기존 함수 재사용)
                _buildFilteredFeed(
                  query: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('createdAt', descending: true),
                  emptyMessage: "등록된 글이 없습니다.",
                ), // 1. 최근 소식 (Firestore 연동)
// 🌟 2. [추가] 좋아요한 글
                user == null
                    ? const Center(child: Text("로그인이 필요합니다."))
                    : _buildFilteredFeed(
                    query: FirebaseFirestore.instance
                        .collection('posts')
                        .where('likedBy', arrayContains: user.uid) // 좋아요한 유저 목록에 내 UID가 있는지 확인
                        .orderBy('createdAt', descending: true),
                    emptyMessage: "좋아요한 게시글이 없습니다."
                ),

                // 🌟 3. [추가] 나의 글
                user == null
                    ? const Center(child: Text("로그인이 필요합니다."))
                    : _buildFilteredFeed(
                    query: FirebaseFirestore.instance
                        .collection('posts')
                        .where('uid', isEqualTo: user.uid) // 작성자가 나인 경우 (필드명이 uid라고 가정)
                        .orderBy('createdAt', descending: true),
                    emptyMessage: "작성한 게시글이 없습니다."
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 🔹 공통 피드 빌더 함수 (중복 제거를 위해 생성)
  Widget _buildFilteredFeed({required Query query, required String emptyMessage}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // 인덱스 생성 필요 에러가 발생할 수 있음 (콘솔 확인 필요)
          return Center(child: Text("데이터 로드 오류: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            return _PostCard(doc: docs[index]); // 기존 _PostCard 위젯 재사용
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

  // ❤️ 좋아요 토글 로직
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
      // 이미 좋아요 한 상태 -> 취소
      await doc.reference.update({
        'likeCount': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      // 좋아요 안 한 상태 -> 추가
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
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("첫 댓글을 남겨보세요!"));
                      }
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
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                        decoration: const InputDecoration(hintText: "댓글을 입력하세요...", border: OutlineInputBorder()),
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

    // 데이터 안전하게 가져오기
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
          // 1. 작성자 정보 헤더
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

          // 2. 게시글 텍스트 (제목 & 내용)
          Text("🌟 추천합니다", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(data['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFF222222))),

          // 3. 해시태그 표시
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: tags.map((t) => Text(t, style: const TextStyle(color: Color(0xFF196DF8), fontSize: 14))).toList(),
            ),
          ],
          const SizedBox(height: 20),

          // 4. ★ 책 정보 카드 (클릭 시 상세 페이지로 이동)
          GestureDetector(
            onTap: () async {
              // (1) 게시글 데이터에서 bookId 가져오기
              final String? bookId = data['bookId'];

              if (bookId == null || bookId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("책 정보를 찾을 수 없습니다.")));
                return;
              }

              try {
                // (2) 실제 books 컬렉션에서 최신 정보 가져오기
                final bookDoc = await FirebaseFirestore.instance.collection('books').doc(bookId).get();

                if (bookDoc.exists) {
                  // (3) BookModel로 변환 후 상세 페이지 이동
                  final realBook = BookModel.fromFirestore(bookDoc);

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: realBook),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되거나 존재하지 않는 책입니다.")));
                  }
                }
              } catch (e) {
                print("책 불러오기 오류: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
                }
              }
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
                      // 책 표지 이미지
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          data['bookImageUrl'] ?? '',
                          width: 73,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 73, color: Colors.grey[300]),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 책 정보 텍스트
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(data['bookTitle'] ?? '제목 없음', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            Text(data['bookAuthor'] ?? '저자 미상', style: const TextStyle(fontSize: 14, color: Color(0xFF777777))),
                            const SizedBox(height: 4),
                            // 평점은 게시글 정보가 아닌 실제 책 정보를 보여주는 것이 좋지만,
                            // 여기서는 UI 표시용으로 게시글 작성 당시 데이터를 쓰거나 비워둡니다.
                            Row( // const 제거 (변수를 쓰므로 const를 빼야 합니다)
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
                                const SizedBox(width: 2),
                                // ★ [수정할 부분] 고정 텍스트 대신 데이터 사용
                                Text(
                                    "${data['bookRating'] ?? '0.0'} (${data['bookReviewCount'] ?? '0'})",
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF777777))
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // '책 보러가기' 버튼 UI
                  const Positioned(
                    right: 10,
                    bottom: 10,
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
              // 좋아요 버튼
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
              // 댓글 버튼
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