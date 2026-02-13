import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용 (pubspec.yaml에 intl 패키지 필요)

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.postData['likeCount'] ?? 0;
    _checkIfLiked();
  }

  // 1. 내가 이 글을 좋아요 했는지 확인
  Future<void> _checkIfLiked() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(_currentUser!.uid)
        .get();

    if (mounted) {
      setState(() => _isLiked = doc.exists);
    }
  }

  // 2. 좋아요 토글 기능 (핵심 로직)
  Future<void> _toggleLike() async {
    if (_currentUser == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final likeRef = postRef.collection('likes').doc(_currentUser!.uid);
    final myLikeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('liked_feeds')
        .doc(widget.postId);

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        // 좋아요 추가
        await likeRef.set({'likedAt': Timestamp.now()});
        await postRef.update({'likeCount': FieldValue.increment(1)});

        // ★ 내 정보 -> 좋아요한 피드에 저장 (마이페이지 연동용)
        await myLikeRef.set({
          'content': widget.postData['content'],
          'bookTitle': widget.postData['bookTitle'] ?? '제목 없음', // 책 제목 필드명 확인 필요
          'likedAt': Timestamp.now(),
        });
      } else {
        // 좋아요 취소
        await likeRef.delete();
        await postRef.update({'likeCount': FieldValue.increment(-1)});

        // ★ 내 정보에서 삭제
        await myLikeRef.delete();
      }
    } catch (e) {
      // 에러 발생 시 롤백
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      print("좋아요 에러: $e");
    }
  }

  // 3. 댓글 작성 기능
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _currentUser == null) return;

    final content = _commentController.text.trim();
    _commentController.clear();

    // 사용자 닉네임 가져오기 (댓글에 표시하기 위함)
    String nickname = '익명';
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    if (userDoc.exists) {
      nickname = userDoc.data()?['nickname'] ?? '익명';
    }

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId': _currentUser!.uid,
      'nickname': nickname,
      'content': content,
      'createdAt': Timestamp.now(),
    });

    // 게시글의 댓글 수 증가 (선택 사항)
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("게시글 상세", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- 게시글 본문 영역 ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 정보 & 날짜
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.postData['nickname'] ?? '알 수 없음',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _formatDate(widget.postData['createdAt']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 내용
                  Text(widget.postData['content'] ?? '', style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 30),

                  // 좋아요 버튼 영역
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey,
                        ),
                      ),
                      Text("$_likeCount"),
                    ],
                  ),
                  const Divider(),
                  const Text("댓글", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // --- 댓글 리스트 (StreamBuilder) ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final comments = snapshot.data!.docs;
                      if (comments.isEmpty) return const Text("첫 댓글을 남겨보세요!", style: TextStyle(color: Colors.grey));

                      return ListView.builder(
                        shrinkWrap: true, // ScrollView 안에 ListView 넣을 때 필수
                        physics: const NeverScrollableScrollPhysics(), // 스크롤은 바깥 SingleChildScrollView가 담당
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var c = comments[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 15)),
                            title: Text(c['nickname'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(c['content']),
                            trailing: Text(
                              _formatDate(c['createdAt']),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- 댓글 입력창 (하단 고정) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "댓글을 입력하세요...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addComment,
                    icon: const Icon(Icons.send, color: Color(0xFFD45858)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('MM/dd HH:mm').format(timestamp.toDate());
    }
    return '';
  }
}