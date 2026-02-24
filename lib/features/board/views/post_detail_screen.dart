import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/custom_network_image.dart';
import '../models/post_model.dart';
import '../controllers/board_controller.dart';
import '../../book/views/book_detail_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _isLiked = user != null && widget.post.likedBy.contains(user.uid);
    _likeCount = widget.post.likeCount;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 좋아요 처리 (Optimistic Update 적용)
  Future<void> _handleLike() async {
    final controller = ref.read(boardControllerProvider);

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await controller.toggleLike(widget.post);
    } catch (e) {
      // 실패 시 롤백
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
    }
  }

  // 댓글 등록 처리
  Future<void> _handleSubmitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await ref.read(boardControllerProvider).addComment(widget.post.id, _commentController.text.trim());
      _commentController.clear();
      FocusScope.of(context).unfocus();

      // 스크롤 아래로 이동
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글 등록 실패")));
    }
  }

  // 책 상세 페이지 이동
  Future<void> _navigateToBookDetail() async {
    if (widget.post.bookId == null) return;

    try {
      final book = await ref.read(boardControllerProvider).getBookDetail(widget.post.bookId!);

      if (mounted) {
        if (book != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("책 정보를 찾을 수 없습니다.")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 댓글 스트림 구독
    final commentsAsync = ref.watch(commentsProvider(widget.post.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("게시글 상세", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 작성자 정보
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
                          Text(widget.post.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            _formatDate(widget.post.createdAt),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF767676)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. 게시글 본문
                  Text(widget.post.content, style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF222222))),

                  const SizedBox(height: 24),

                  // 3. 책 정보 카드 (존재할 경우에만 표시)
                  if (widget.post.bookId != null)
                    GestureDetector(
                      onTap: _navigateToBookDetail,
                      child: Container(
                        height: 100,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CustomNetworkImage(
                                imageUrl: widget.post.bookImageUrl ?? '',
                                width: 55,
                                height: 80,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.post.bookTitle ?? '제목 없음',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.post.bookAuthor ?? '저자 미상',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF767676)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF999999)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // 4. 좋아요 버튼
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _handleLike,
                        child: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? const Color(0xFFD45858) : const Color(0xFF999999),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("좋아요 $_likeCount", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1, color: Color(0xFFF1F1F5)),
                  const SizedBox(height: 20),

                  // 5. 댓글 목록
                  const Text("댓글", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  commentsAsync.when(
                    data: (docs) {
                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text("아직 댓글이 없습니다. 첫 댓글을 남겨보세요!", style: TextStyle(color: Color(0xFF999999)))),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return _buildCommentItem(data);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Text("댓글을 불러올 수 없습니다."),
                  ),
                ],
              ),
            ),
          ),

          // 6. 하단 댓글 입력창
          _buildBottomInput(),
        ],
      ),
    );
  }

  // 헬퍼: 댓글 아이템 위젯
  Widget _buildCommentItem(Map<String, dynamic> data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(radius: 16, backgroundColor: Color(0xFFF1F1F5), child: Icon(Icons.person, size: 18, color: Colors.grey)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data['nickname'] ?? '익명', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_formatDate((data['createdAt'] as Timestamp?)?.toDate()), style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
              const SizedBox(height: 4),
              Text(data['content'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
            ],
          ),
        ),
      ],
    );
  }

// 헬퍼: 하단 입력창 위젯
  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              // 🌟 [최종 해결책] Theme 위젯으로 감싸서 글로벌 테마(빨간색)를 완벽히 차단!
              child: Theme(
                data: Theme.of(context).copyWith(
                  // 메인 컬러를 검정/회색으로 덮어쓰기
                  primaryColor: Colors.black,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Colors.black,
                  ),
                  // 글자 드래그 시 배경색 & 복사 물방울 커서 색상까지 전부 무채색으로 강제 고정
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Colors.black,
                    selectionColor: Color(0xFFEEEEEE),
                    selectionHandleColor: Colors.black,
                  ),
                ),
                child: TextField(
                  controller: _commentController,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    hintText: "댓글을 입력하세요...",
                    filled: true,
                    fillColor: Colors.white,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSubmitComment,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD45858), // 종이비행기 버튼은 빨간색 유지
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MM/dd HH:mm').format(date);
  }
}