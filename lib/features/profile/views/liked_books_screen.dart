import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/custom_network_image.dart';

import '../../book/views/book_detail_screen.dart';
import '../controllers/profile_controller.dart';

class LikedBooksScreen extends ConsumerStatefulWidget {
  const LikedBooksScreen({super.key});

  @override
  ConsumerState<LikedBooksScreen> createState() => _LikedBooksScreenState();
}

class _LikedBooksScreenState extends ConsumerState<LikedBooksScreen> {
  bool _isLoading = false; // 중복 클릭방지

  // 책 클릭 시 상세 정보 불러오기
  void _handleBookTap(String bookId) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final book = await ref.read(profileActionControllerProvider).getBookDetail(bookId);

      if (mounted) {
        if (book != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("정보를 불러올 수 없는 책입니다.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("책 정보를 불러오는 중 오류가 발생했습니다.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final likedBooksAsync = ref.watch(likedBooksProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("좋아요한 책 전체보기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          likedBooksAsync.when(
            data: (snapshot) {
              final docs = snapshot.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("좋아요한 책이 없습니다.", style: TextStyle(color: Colors.grey)));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final bookId = docs[index].id;

                  return GestureDetector(
                    onTap: () => _handleBookTap(bookId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomNetworkImage(
                                imageUrl: data['imageUrl'] ?? '',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['title'] ?? '제목 없음',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text("오류가 발생했습니다: $error")),
          ),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}