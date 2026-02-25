import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../controllers/admin_controller.dart';
import 'admin_add_book_screen.dart';
import '../../../shared/widgets/custom_network_image.dart';

class AdminBookListScreen extends ConsumerWidget {
  const AdminBookListScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("정말 삭제하시겠습니까?"),
        content: const Text("이 작업은 되돌릴 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminControllerProvider.notifier).deleteBook(book.id, book.imageUrl);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 [핵심 변경] 원본 대신 '검색+정렬'이 적용된 파생 Provider를 구독합니다!
    final booksAsync = ref.watch(filteredAndSortedBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("등록된 책 관리")),
      body: Column(
        children: [
          // 상단 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '책 제목 또는 저자 검색',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // 글자를 입력할 때마다 검색어 상태를 업데이트
                ref.read(adminSearchQueryProvider.notifier).updateQuery(value);
              },
            ),
          ),

          // 하단 리스트 영역
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('에러 발생: $error')),
              data: (books) {
                if (books.isEmpty) {
                  return const Center(child: Text("검색 결과가 없거나 등록된 책이 없습니다."));
                }

                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CustomNetworkImage(
                          imageUrl: book.imageUrl,
                          width: 40,
                          height: 60,
                        ),
                        title: Text(
                          "${book.rank}위 | ${book.title}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text("${book.author} | 평점 ${book.rating}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _confirmDelete(context, ref, book),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminAddBookScreen(bookToEdit: book),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}