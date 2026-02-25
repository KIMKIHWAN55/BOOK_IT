import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../controllers/admin_controller.dart';
import 'admin_add_book_screen.dart';
import '../../../shared/widgets//custom_network_image.dart';

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
    final booksAsync = ref.watch(adminBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("등록된 책 관리")),
      body: booksAsync.when(
        // 데이터 로딩 중
        loading: () => const Center(child: CircularProgressIndicator()),

        // 에러 발생 시
        error: (error, stack) => Center(child: Text('에러 발생: $error')),

        // 데이터 성공 시
        data: (books) {
          if (books.isEmpty) {
            return const Center(child: Text("등록된 책이 없습니다."));
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
                  title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${book.author} | ${book.rank}위"),
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
    );
  }
}