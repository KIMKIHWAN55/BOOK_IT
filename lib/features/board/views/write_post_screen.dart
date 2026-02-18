import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../controllers/board_controller.dart';

class WritePostScreen extends ConsumerStatefulWidget {
  const WritePostScreen({super.key});

  @override
  ConsumerState<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends ConsumerState<WritePostScreen> {
  final TextEditingController _contentController = TextEditingController();

  // UI 상태 (선택된 책)
  BookModel? _selectedBook;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // 💾 게시글 저장 요청 (Controller 호출)
  Future<void> _handleSavePost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
      return;
    }
    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책을 선택해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🌟 Controller에게 저장 위임
      await ref.read(boardControllerProvider).writePost(
        content: _contentController.text,
        book: _selectedBook!,
      );

      if (mounted) Navigator.pop(context); // 성공 시 닫기
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 📖 책 선택 바텀 시트 (Riverpod Provider 사용)
  void _showBookSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("책 선택하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                // 🌟 StreamBuilder 대신 Consumer 위젯 사용
                child: Consumer(
                  builder: (context, ref, _) {
                    final booksAsync = ref.watch(booksProvider);

                    return booksAsync.when(
                      data: (books) {
                        if (books.isEmpty) return const Center(child: Text("등록된 책이 없습니다."));

                        return ListView.separated(
                          itemCount: books.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  book.imageUrl,
                                  width: 40, height: 60, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 40, color: Colors.grey[300]),
                                ),
                              ),
                              title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(book.author),
                                  if (book.tags.isNotEmpty)
                                    Text(
                                      book.tags.join(' '),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF196DF8)),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              onTap: () {
                                setState(() => _selectedBook = book);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('오류: $err')),
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
        title: const Text("글쓰기", style: TextStyle(fontFamily: 'Pretendard', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
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
                    style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF222222)),
                    decoration: const InputDecoration(
                      hintText: "내용을 입력해 주세요. (예: #감성 #힐링)",
                      hintStyle: TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF999999)),
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
                        ? const Stack(
                      children: [
                        Positioned(
                          right: 30, top: 43,
                          child: Row(
                            children: [
                              Text("책 추천하기", style: TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF111111))),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF222222)),
                            ],
                          ),
                        ),
                      ],
                    )
                        : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _selectedBook!.imageUrl,
                              width: 50, height: 76, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 50, height: 76, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_selectedBook!.title, style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(_selectedBook!.author, style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Colors.grey)),
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
              onTap: _isLoading ? null : _handleSavePost,
              child: Container(
                height: 60,
                decoration: BoxDecoration(color: const Color(0xFFD45858), borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("작성 하기", style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}