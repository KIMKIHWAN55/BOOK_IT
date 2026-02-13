import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../book/models/book_model.dart';
import 'admin_add_book_screen.dart';

class AdminBookListScreen extends StatelessWidget {
  const AdminBookListScreen({super.key});

  // 🗑️ 삭제 함수
  void _deleteBook(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("정말 삭제하시겠습니까?"),
        content: const Text("이 작업은 되돌릴 수 없습니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('books').doc(docId).delete();
              // (선택) 스토리지 이미지 삭제 로직도 추가 가능
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("등록된 책 관리")),
      body: StreamBuilder<QuerySnapshot>(
        // 최신 등록순으로 정렬
        stream: FirebaseFirestore.instance.collection('books').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("등록된 책이 없습니다."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // Firestore 데이터를 모델로 변환
              final doc = snapshot.data!.docs[index];
              final book = BookModel.fromFirestore(doc);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Image.network(book.imageUrl, width: 40, height: 60, fit: BoxFit.cover),
                  title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${book.author} | ${book.rank}위"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => _deleteBook(context, book.id), // 🗑️ 삭제 버튼
                  ),
                  onTap: () {
                    // ✏️ 수정 모드로 이동 (책 데이터를 넘겨줌)
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