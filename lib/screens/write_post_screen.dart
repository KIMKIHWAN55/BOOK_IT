import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookit_app/models/book_model.dart'; // ★ BookModel 임포트 필수

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({super.key});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final TextEditingController _contentController = TextEditingController();

  // ★ 선택된 책을 BookModel 객체로 저장
  BookModel? _selectedBook;
  bool _isLoading = false;

  // 🔸 Pretendard 스타일 헬퍼
  TextStyle _ptStyle({
    required double size,
    required FontWeight weight,
    Color color = const Color(0xFF000000),
    double? height,
    double? spacing,
  }) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );
  }

  // 🏷️ 본문에서 해시태그 추출 함수
  List<String> _extractHashTags(String text) {
    final RegExp regex = RegExp(r"\#([^\s]+)");
    final Iterable<Match> matches = regex.allMatches(text);
    return matches.map((m) => "#${m.group(1)}").toList();
  }

  // 💾 게시글 저장 로직
  Future<void> _savePost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
      return;
    }
    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책을 선택해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String nickname = '익명';
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) nickname = userDoc.data()!['nickname'] ?? '익명';
      } catch (e) {
        print("유저 정보 로드 실패: $e");
      }

      // 1. 본문에서 태그 추출
      List<String> finalTags = _extractHashTags(_contentController.text);

      // 2. ★ 선택한 책의 태그도 자동으로 추가 (중복 제거)
      if (_selectedBook != null && _selectedBook!.tags.isNotEmpty) {
        finalTags.addAll(_selectedBook!.tags);
      }
      finalTags = finalTags.toSet().toList(); // 중복 태그 제거

      // 3. Firestore 저장
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,
        'nickname': nickname,
        'content': _contentController.text,

        // ★ 선택된 책 정보 저장 (BookModel 데이터 활용)
        'bookTitle': _selectedBook!.title,
        'bookAuthor': _selectedBook!.author,
        'bookImageUrl': _selectedBook!.imageUrl,

        'tags': finalTags, // 합쳐진 태그 리스트 저장
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 📖 책 선택 바텀 시트 (Firestore 연동)
  void _showBookSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 500, // 높이 조금 확보
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("책 선택하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                // ★ Firestore 'books' 컬렉션에서 실시간 불러오기
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('books').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("등록된 책이 없습니다."));
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        // DB 데이터를 BookModel로 변환
                        final book = BookModel.fromFirestore(docs[index]);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              book.imageUrl,
                              width: 40, height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 40, color: Colors.grey[300]),
                            ),
                          ),
                          title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.author),
                              // 책의 태그 미리보기
                              if (book.tags.isNotEmpty)
                                Text(
                                  book.tags.join(' '),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF196DF8)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedBook = book;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("글쓰기", style: _ptStyle(size: 20, weight: FontWeight.w600, spacing: -0.5)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 38),
                // 1. 내용 입력
                Container(
                  width: double.infinity,
                  height: 435,
                  decoration: BoxDecoration(color: const Color(0xFFF1F1F5), borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: _ptStyle(size: 16, weight: FontWeight.w400, color: const Color(0xFF222222)),
                    decoration: InputDecoration(
                      hintText: "내용을 입력해 주세요. (예: #감성 #힐링)",
                      hintStyle: _ptStyle(size: 16, weight: FontWeight.w400, color: const Color(0xFF222222), spacing: -0.408),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. 책 추천 박스
                GestureDetector(
                  onTap: _showBookSelector,
                  child: Container(
                    width: double.infinity,
                    height: 108,
                    decoration: BoxDecoration(color: const Color(0xFFF1F1F5), borderRadius: BorderRadius.circular(20)),
                    child: _selectedBook == null
                        ? Stack( // 책 선택 전
                      children: [
                        Positioned(
                          right: 30, top: 43,
                          child: Row(
                            children: [
                              Text("책 추천하기", style: _ptStyle(size: 16, weight: FontWeight.w400, color: const Color(0xFF111111), spacing: -0.8)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF222222)),
                            ],
                          ),
                        ),
                      ],
                    )
                        : Padding( // 책 선택 후 (태그 표시 추가됨)
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _selectedBook!.imageUrl,
                              width: 50, height: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 50, height: 76, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_selectedBook!.title, style: _ptStyle(size: 16, weight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(_selectedBook!.author, style: _ptStyle(size: 14, weight: FontWeight.w400, color: Colors.grey)),
                                // ★ 선택된 책의 태그 미리보기
                                if (_selectedBook!.tags.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedBook!.tags.join(' '),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF196DF8)),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Color(0xFFD45858)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          // 3. 작성하기 버튼
          Positioned(
            left: 16, right: 16, bottom: 34,
            child: GestureDetector(
              onTap: _isLoading ? null : _savePost,
              child: Container(
                height: 60,
                decoration: BoxDecoration(color: const Color(0xFFD45858), borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("작성 하기", style: _ptStyle(size: 18, weight: FontWeight.w600, color: Colors.white, spacing: -0.45)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}