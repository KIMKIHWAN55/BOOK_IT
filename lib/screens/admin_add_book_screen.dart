import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class AdminAddBookScreen extends StatefulWidget {
  const AdminAddBookScreen({super.key});

  @override
  State<AdminAddBookScreen> createState() => _AdminAddBookScreenState();
}

class _AdminAddBookScreenState extends State<AdminAddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // 입력 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // 🔹 추가된 필드 컨트롤러
  final TextEditingController _descriptionController = TextEditingController(); // 줄거리
  final TextEditingController _priceController = TextEditingController();       // 가격
  final TextEditingController _discountController = TextEditingController();    // 할인율
  final TextEditingController _tagsController = TextEditingController();        // 태그 (#SF, #소설)

  Future<void> _registerBook() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 태그 문자열을 리스트로 변환 (쉼표로 구분)
        List<String> tagsList = _tagsController.text.isNotEmpty
            ? _tagsController.text.split(',').map((e) => e.trim()).toList()
            : [];

        // 새 BookModel 객체 생성
        final newBook = BookModel(
          id: '', // Firestore에서 자동 생성됨
          title: _titleController.text,
          author: _authorController.text,
          imageUrl: _imageUrlController.text,
          rank: _rankController.text,
          category: _categoryController.text,
          rating: '0.0', // 초기값
          reviewCount: '0', // 초기값
          // 🔹 추가된 상세 정보
          description: _descriptionController.text,
          price: int.tryParse(_priceController.text) ?? 0,
          discountRate: int.tryParse(_discountController.text),
          tags: tagsList,
        );

        // Firestore에 저장
        await FirebaseFirestore.instance.collection('books').add(newBook.toMap());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 등록 성공! 📚')));
        Navigator.pop(context); // 등록 후 이전 화면으로 이동
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("책 등록하기 (관리자)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_titleController, '책 제목', '예: Paradox'),
              _buildTextField(_authorController, '작가', '예: 호베루투 카를로스'),
              _buildTextField(_imageUrlController, '이미지 URL', 'https://...'),
              _buildTextField(_rankController, '순위', '예: 1'),
              _buildTextField(_categoryController, '카테고리', '예: 소설'),

              const Divider(height: 40, thickness: 2),
              const Text("📖 상세 페이지 정보", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _buildTextField(_priceController, '정가 (원)', '예: 13000', isNumber: true),
              _buildTextField(_discountController, '할인율 (%)', '예: 10 (선택사항)', isNumber: true),
              _buildTextField(_tagsController, '태그 (쉼표로 구분)', '예: #SF, #미스테리, #소설'),

              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '줄거리',
                  border: OutlineInputBorder(),
                  hintText: '책의 줄거리를 입력하세요.',
                ),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _registerBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text("책 등록 완료", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (!isNumber && (value == null || value.isEmpty)) {
            return '$label을(를) 입력해주세요';
          }
          return null;
        },
      ),
    );
  }
}