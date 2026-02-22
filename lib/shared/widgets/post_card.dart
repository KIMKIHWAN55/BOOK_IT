import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookit_app/features/board/controllers/board_controller.dart';
import 'package:bookit_app/features/board/models/post_model.dart';
import 'package:bookit_app/features/board/repositories/board_repository.dart';
import 'package:bookit_app/features/book/views/book_detail_screen.dart';

import '../../../core/router/app_router.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  // 🌟 작성 및 수정 시간을 계산해서 예쁜 문자열로 바꿔주는 함수
  String _getTimeString(PostModel post) {
    final targetTime = post.updatedAt ?? post.createdAt;
    final isEdited = post.updatedAt != null;

    final now = DateTime.now();
    final difference = now.difference(targetTime);

    String timeText;
    if (difference.inSeconds < 60) {
      timeText = "방금 전";
    } else if (difference.inMinutes < 60) {
      timeText = "${difference.inMinutes}분 전";
    } else if (difference.inHours < 24) {
      timeText = "${difference.inHours}시간 전";
    } else if (difference.inDays < 30) {
      timeText = "${difference.inDays}일 전";
    } else {
      timeText = "${targetTime.year}.${targetTime.month.toString().padLeft(2, '0')}.${targetTime.day.toString().padLeft(2, '0')}";
    }

    return isEdited ? "$timeText 수정됨" : timeText;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(boardControllerProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = user != null && post.likedBy.contains(user.uid);

    // 현재 로그인한 유저가 이 글의 작성자인지 확인
    final isMyPost = user != null && user.uid == post.uid;

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
          // 1. 헤더 (작성자 + 더보기 메뉴)
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDBDBDB),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.nickname, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(_getTimeString(post), style: const TextStyle(fontSize: 12, color: Color(0xFF767676))),
                  ],
                ),
              ),

              // 내 글일 때만 보이는 우측 상단 더보기 메뉴
              if (isMyPost)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF767676)),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.pushNamed(context, AppRouter.writePost, arguments: post);
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(context, ref, post.id);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('수정하기', style: TextStyle(fontFamily: 'Pretendard', fontSize: 14)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제하기', style: TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Colors.red)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 내용
          const Text("🌟 추천합니다", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(post.content, style: const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFF222222))),

          // 3. 태그
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: post.tags.map((t) => Text(t, style: const TextStyle(color: Color(0xFF196DF8), fontSize: 14))).toList(),
            ),
          ],
          const SizedBox(height: 20),

          // 4. 책 카드 (클릭 시 이동)
          if (post.bookId != null)
            GestureDetector(
              onTap: () async {
                final book = await controller.getBookDetail(post.bookId!);
                if (context.mounted) {
                  if (book != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("책 정보를 찾을 수 없습니다.")));
                  }
                }
              },
              child: _buildBookInfoCard(post),
            ),

          const SizedBox(height: 20),

          // 5. 하단 버튼 (좋아요, 댓글)
          Row(
            children: [
              // 좋아요
              GestureDetector(
                onTap: () async {
                  try {
                    await controller.toggleLike(post);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 24,
                      color: isLiked ? const Color(0xFFD45858) : const Color(0xFF222222),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${post.likeCount}",
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
                onTap: () => _showCommentSheet(context, ref, post),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 24, color: Color(0xFF222222)),
                    const SizedBox(width: 4),
                    Text("${post.commentCount}", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, String postId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('게시글 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: const Text('정말 이 게시글을 삭제하시겠습니까?\n삭제된 글은 복구할 수 없습니다.', style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(boardControllerProvider).deletePost(postId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('게시글이 삭제되었습니다.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('삭제 실패: $e')),
                    );
                  }
                }
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🔹 책 정보 위젯
  Widget _buildBookInfoCard(PostModel post) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF1F1F5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              post.bookImageUrl ?? '',
              width: 73, height: 110, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 73, color: Colors.grey[300]),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(post.bookTitle ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                Text(post.bookAuthor ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF777777))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
                    const SizedBox(width: 2),
                    Text("${post.bookRating} (${post.bookReviewCount})", style: const TextStyle(fontSize: 12, color: Color(0xFF777777))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 [수정됨] 기존에 길었던 코드를 지우고, 새로 만든 분리된 위젯을 호출하도록 변경
  void _showCommentSheet(BuildContext context, WidgetRef ref, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => CommentBottomSheet(post: post),
    );
  }
}

// ======================================================================
// 🌟 [새로 추가됨] 대댓글과 삭제 기능이 포함된 완벽한 댓글 바텀시트 위젯
// ======================================================================
class CommentBottomSheet extends ConsumerStatefulWidget {
  final PostModel post;
  const CommentBottomSheet({super.key, required this.post});

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  // 대댓글 작성을 위한 상태 변수
  String? _replyingToCommentId; // 어떤 댓글에 답글을 다는지
  String? _replyingToNickname;  // 누구에게 답글을 다는지 (UI 표시용)

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 시간 계산 헬퍼
  String _getTimeString(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 60) return "방금 전";
    if (difference.inMinutes < 60) return "${difference.inMinutes}분 전";
    if (difference.inHours < 24) return "${difference.inHours}시간 전";
    if (difference.inDays < 30) return "${difference.inDays}일 전";
    return "${time.year}.${time.month.toString().padLeft(2, '0')}.${time.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7, // 넉넉한 높이
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("댓글", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 1. 댓글 리스트
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ref.read(boardRepositoryProvider).getCommentsStream(widget.post.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("첫 댓글을 남겨보세요!", style: TextStyle(color: Colors.grey)));
                  }

                  final allDocs = snapshot.data!.docs;

                  // 🌟 부모 댓글과 대댓글 분리 및 정렬 로직
                  final parentComments = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['parentId'] == null).toList();
                  final childComments = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['parentId'] != null).toList();

                  // 화면에 그릴 순서대로 리스트 재조립 (부모 -> 자식1 -> 자식2 -> 부모2...)
                  List<QueryDocumentSnapshot> displayList = [];
                  for (var parent in parentComments) {
                    displayList.add(parent);
                    displayList.addAll(childComments.where((child) => (child.data() as Map<String, dynamic>)['parentId'] == parent.id));
                  }

                  return ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final doc = displayList[index];
                      final cData = doc.data() as Map<String, dynamic>;
                      final isChild = cData['parentId'] != null;
                      final isDeleted = cData['isDeleted'] == true;
                      final isMyComment = currentUserId == cData['uid'];

                      final createdAt = (cData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                      return Container(
                        // 🌟 대댓글이면 왼쪽 여백을 주어 들여쓰기 효과
                        padding: EdgeInsets.only(left: isChild ? 40 : 0, top: 12, bottom: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isChild) const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                            if (isChild) const SizedBox(width: 8),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 닉네임 & 시간 & 삭제 버튼
                                  Row(
                                    children: [
                                      Text(cData['nickname'] ?? '익명', style: TextStyle(fontWeight: FontWeight.w600, color: isDeleted ? Colors.grey : Colors.black)),
                                      const SizedBox(width: 8),
                                      Text(_getTimeString(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const Spacer(),
                                      // 🌟 내 댓글이고 삭제되지 않은 상태일 때만 '삭제' 버튼 표시
                                      if (isMyComment && !isDeleted)
                                        GestureDetector(
                                          onTap: () async {
                                            await ref.read(boardControllerProvider).deleteComment(widget.post.id, doc.id);
                                          },
                                          child: const Text("삭제", style: TextStyle(fontSize: 12, color: Colors.red)),
                                        )
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // 내용 (삭제된 글이면 회색 처리)
                                  Text(
                                    cData['content'] ?? '',
                                    style: TextStyle(
                                      color: isDeleted ? Colors.grey : const Color(0xFF222222),
                                      fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                    ),
                                  ),

                                  // 🌟 부모 댓글이고, 삭제되지 않았을 때만 '답글 달기' 버튼 표시
                                  if (!isChild && !isDeleted)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _replyingToCommentId = doc.id;
                                            _replyingToNickname = cData['nickname'];
                                          });
                                        },
                                        child: const Text("답글 달기", style: TextStyle(fontSize: 12, color: Color(0xFF767676), fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 2. 대댓글 작성 중일 때 표시되는 상태 바
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Text("$_replyingToNickname님에게 답글 남기는 중...", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _replyingToCommentId = null;
                        _replyingToNickname = null;
                      }),
                      child: const Icon(Icons.close, size: 16),
                    )
                  ],
                ),
              ),

            // 3. 댓글 입력창
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _replyingToCommentId != null ? "답글을 입력하세요..." : "댓글을 남겨보세요...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF1F1F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    if (_commentController.text.trim().isNotEmpty) {
                      try {
                        await ref.read(boardControllerProvider).addComment(
                          widget.post.id,
                          _commentController.text.trim(),
                          parentId: _replyingToCommentId, // 🌟 대댓글이면 ID 전달
                        );
                        _commentController.clear();
                        setState(() {
                          _replyingToCommentId = null;
                          _replyingToNickname = null;
                        });
                        FocusScope.of(context).unfocus();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("등록 실패")));
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFFD45858), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}