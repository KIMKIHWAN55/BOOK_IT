import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp 등 UI 표시용
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookit_app/features/board/controllers/board_controller.dart';
import 'package:bookit_app/features/board/models/post_model.dart';
import 'package:bookit_app/features/board/repositories/board_repository.dart'; // 댓글 스트림용
import 'package:bookit_app/features/book/views/book_detail_screen.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(boardControllerProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = user != null && post.likedBy.contains(user.uid);

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
          // 1. 헤더 (작성자)
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
                  Text(post.nickname, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  // 시간 계산 로직은 별도 유틸로 빼면 좋음 (여기선 간단히)
                  const Text("방금 전", style: TextStyle(fontSize: 12, color: Color(0xFF767676))),
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

  // 🔹 책 정보 위젯 (UI 코드 분리)
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

  // 🔹 댓글 바텀시트
  void _showCommentSheet(BuildContext context, WidgetRef ref, PostModel post) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("댓글 남기기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: ref.read(boardRepositoryProvider).getCommentsStream(post.id),
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
                            subtitle: Text("익명 · 방금 전", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                      onPressed: () async {
                        if (commentController.text.isNotEmpty) {
                          try {
                            await ref.read(boardControllerProvider).addComment(post.id, commentController.text);
                            commentController.clear();
                            // 키보드 내리기 등 추가 UX 처리 가능
                          } catch (e) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("댓글 등록 실패")));
                          }
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
}