import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 갤러리 이미지 선택
import 'package:firebase_storage/firebase_storage.dart'; // 이미지 업로드
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
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  // 📸 이미지 관련 변수
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // 로딩 상태

  // 1. 갤러리에서 이미지 선택 함수
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // 2. 이미지를 Firebase Storage에 업로드하고 URL을 받는 함수
  Future<String> _uploadImageToStorage() async {
    if (_selectedImage == null) return '';

    try {
      // 파일명 생성 (현재시간_파일명)
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_book_cover.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('book_covers/$fileName');

      // 업로드 수행
      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;

      // 다운로드 URL 받기
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('이미지 업로드 실패: $e');
      return '';
    }
  }

  // 3. 책 등록 함수 (이미지 업로드 -> Firestore 저장)
  Future<void> _registerBook() async {
    if (!_formKey.currentState!.validate()) return;

    // 이미지가 선택되지 않았을 경우 경고
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('책 표지 이미지를 등록해주세요! 📷')),
      );
      return;
    }

    setState(() => _isLoading = true); // 로딩 시작

    try {
      // (1) 이미지 먼저 업로드하고 URL 받아오기
      String downloadUrl = await _uploadImageToStorage();

      if (downloadUrl.isEmpty) {
        throw Exception("이미지 업로드에 실패했습니다.");
      }

      // (2) 태그 리스트 변환
      List<String> tagsList = _tagsController.text.isNotEmpty
          ? _tagsController.text.split(',').map((e) => e.trim()).toList()
          : [];

      // (3) 모델 생성
      final newBook = BookModel(
        id: '',
        title: _titleController.text,
        author: _authorController.text,
        imageUrl: downloadUrl, // 👈 업로드된 이미지 URL 사용
        rank: _rankController.text,
        category: _categoryController.text,
        rating: '0.0',
        reviewCount: '0',
        description: _descriptionController.text,
        price: int.tryParse(_priceController.text) ?? 0,
        discountRate: int.tryParse(_discountController.text),
        tags: tagsList,
      );

      // (4) Firestore 저장
      await FirebaseFirestore.instance.collection('books').add(newBook.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 등록 성공! 📚')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false); // 로딩 종료
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("책 등록하기 (관리자)")),
      // 🔹 Stack을 사용하여 로딩 화면을 위에 띄움
      body: Stack(
        children: [
          // 📜 스크롤 가능한 폼 영역
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📸 이미지 선택 영역
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                        image: _selectedImage != null
                            ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text("표지 등록", style: TextStyle(color: Colors.grey)),
                        ],
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(_titleController, '책 제목', '예: Paradox'),
                  _buildTextField(_authorController, '작가', '예: 호베루투 카를로스'),
                  // 이미지 URL 입력 필드는 삭제됨 (자동 처리)

                  Row(
                    children: [
                      Expanded(child: _buildTextField(_rankController, '순위', '예: 1')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_categoryController, '카테고리', '예: 소설')),
                    ],
                  ),

                  const Divider(height: 40, thickness: 2),
                  const Text("📖 상세 페이지 정보", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(child: _buildTextField(_priceController, '정가 (원)', '예: 13000', isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_discountController, '할인율 (%)', '예: 10', isNumber: true)),
                    ],
                  ),

                  _buildTextField(_tagsController, '태그 (쉼표로 구분)', '예: #SF, #미스테리, #소설'),

                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: '줄거리',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      hintText: '책의 줄거리를 입력하세요.',
                    ),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("책 등록 완료", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20), // 하단 여백 추가
                ],
              ),
            ),
          ),

          // ⏳ 로딩 인디케이터 (업로드 중일 때만 표시)
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: (value) {
          if (!isNumber && (value == null || value.isEmpty)) {
            return '입력해주세요';
          }
          return null;
        },
      ),
    );
  }
}