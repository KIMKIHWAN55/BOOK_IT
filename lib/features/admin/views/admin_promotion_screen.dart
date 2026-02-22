import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../book/models/book_model.dart';
import '../controllers/admin_controller.dart';

class AdminPromotionScreen extends ConsumerStatefulWidget {
  const AdminPromotionScreen({super.key});

  @override
  ConsumerState<AdminPromotionScreen> createState() => _AdminPromotionScreenState();
}

class _AdminPromotionScreenState extends ConsumerState<AdminPromotionScreen> {
  // 체크된 책들의 ID를 저장할 리스트
  List<String> _selectedBookIds = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRecommendations();
  }

  // 1. 기존에 등록되어 있던 추천 도서 목록을 불러와서 미리 체크해둠
  Future<void> _loadCurrentRecommendations() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('promotions').doc('weekly_recommend').get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic> ids = doc.data()!['bookIds'] ?? [];
        setState(() {
          _selectedBookIds = List<String>.from(ids);
        });
      }
    } catch (e) {
      debugPrint("기존 추천 도서 로드 실패: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 2. 체크박스 선택/해제 토글 로직
  void _toggleSelection(String bookId) {
    setState(() {
      if (_selectedBookIds.contains(bookId)) {
        _selectedBookIds.remove(bookId); // 이미 있으면 제거 (체크 해제)
      } else {
        // 🌟 실무 팁: UI가 망가지지 않도록 추천 도서 개수를 5개로 제한
        if (_selectedBookIds.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('추천 도서는 최대 5개까지만 선택 가능합니다.')),
          );
          return;
        }
        _selectedBookIds.add(bookId); // 없으면 추가 (체크)
      }
    });
  }

  // 3. 서버에 저장하기
  Future<void> _saveRecommendations() async {
    if (_selectedBookIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소 1권 이상의 책을 선택해주세요.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // AdminController의 저장 함수 호출
      await ref.read(adminControllerProvider.notifier).updateRecommendedBooks(_selectedBookIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이번 주 추천 도서가 업데이트 되었습니다!')));
        Navigator.pop(context); // 저장 후 뒤로가기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "추천 도서 관리",
          style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          // 🌟 저장 버튼
          TextButton(
            onPressed: _isLoading || _isSaving ? null : _saveRecommendations,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("저장", style: TextStyle(color: Color(0xFFD45858), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            width: double.infinity,
            child: Text(
              "선택됨: ${_selectedBookIds.length} / 5",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF196DF8)),
            ),
          ),
          Expanded(
            // 모든 책을 실시간으로 가져와서 리스트로 뿌려줌
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('books').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final books = snapshot.data!.docs;
                if (books.isEmpty) return const Center(child: Text("등록된 책이 없습니다."));

                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final doc = books[index];
                    final book = BookModel.fromFirestore(doc);
                    final isSelected = _selectedBookIds.contains(book.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      color: Colors.white,
                      child: CheckboxListTile(
                        activeColor: const Color(0xFFD45858),
                        value: isSelected,
                        onChanged: (bool? value) => _toggleSelection(book.id),
                        title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("${book.author} · ${book.category}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        secondary: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            book.imageUrl,
                            width: 40, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 40, color: Colors.grey),
                          ),
                        ),
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