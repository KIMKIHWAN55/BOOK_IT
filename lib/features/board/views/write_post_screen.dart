import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../controllers/board_controller.dart';
import '../../../shared/widgets/custom_network_image.dart';
import '../models/post_model.dart';

class WritePostScreen extends ConsumerStatefulWidget {
  final PostModel? editingPost;

  const WritePostScreen({super.key, this.editingPost});

  @override
  ConsumerState<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends ConsumerState<WritePostScreen> {
  late TextEditingController _contentController;
  BookModel? _selectedBook;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _contentController = TextEditingController(
        text: widget.editingPost?.content ?? ''
    );

    if (widget.editingPost != null && widget.editingPost!.bookId != null) {
      // 기존 글에 책이 있었다면 화면에 보여주기 위해 임시 BookModel 생성
      _selectedBook = BookModel(
        id: widget.editingPost!.bookId!,
        title: widget.editingPost!.bookTitle ?? '',
        author: widget.editingPost!.bookAuthor ?? '',
        imageUrl: widget.editingPost!.bookImageUrl ?? '',
        rating: widget.editingPost!.bookRating.toString(),
        reviewCount: widget.editingPost!.bookReviewCount.toString(),

        rank: 0,
        tags: [],
        description: '',
        category: '',
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

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
      if (widget.editingPost != null) {
        // [수정]
        await ref.read(boardControllerProvider).updatePost(
          postId: widget.editingPost!.id,
          content: _contentController.text,
          book: _selectedBook,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 수정되었습니다.')));
        }
      } else {
        // [작성]
        await ref.read(boardControllerProvider).writePost(
          content: _contentController.text,
          book: _selectedBook!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('새 게시글이 등록되었습니다.')));
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                                child: CustomNetworkImage(
                                  imageUrl: book.imageUrl,
                                  width: 40,
                                  height: 60,
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
    final screenTitle = widget.editingPost != null ? "글 수정하기" : "글쓰기";
    final buttonTitle = widget.editingPost != null ? "수정 하기" : "작성 하기";

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
        title: Text(screenTitle, style: const TextStyle(fontFamily: 'Pretendard', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 38),
                //  내용 입력
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

                //  책 추천 박스
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
                            child: CustomNetworkImage(
                              imageUrl: _selectedBook!.imageUrl,
                              width: 50,
                              height: 76,
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
                const SizedBox(height: 100), // 하단 버튼이 가리지 않도록 여백 추가
              ],
            ),
          ),

          // 작성하기/수정하기 버튼
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
                    : Text(buttonTitle, style: const TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}