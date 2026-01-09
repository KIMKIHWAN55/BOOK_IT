import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookit_app/models/book_model.dart';

class AdminAddBookScreen extends StatefulWidget {
  const AdminAddBookScreen({super.key});

  @override
  State<AdminAddBookScreen> createState() => _AdminAddBookScreenState();
}

class _AdminAddBookScreenState extends State<AdminAddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // 입력 필드 컨트롤러
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _rankController = TextEditingController();
  final _ratingController = TextEditingController();
  final _reviewCountController = TextEditingController();

  String _selectedCategory = 'bestseller'; // 기본값
  File? _pickedImage;
  bool _isLoading = false;

  // 🔸 갤러리에서 이미지 선택 함수
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // 🔸 이미지 업로드 및 데이터 저장 메인 함수
  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate() || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 선택하고 모든 필드를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Storage에 이미지 업로드
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('book_covers/$fileName');
      UploadTask uploadTask = ref.putFile(_pickedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // 2. Firestore에 데이터 저장
      final newBook = BookModel(
        id: '', // Firestore 자동 생성을 위해 빈 값
        rank: _rankController.text,
        title: _titleController.text,
        author: _authorController.text,
        imageUrl: imageUrl,
        rating: _ratingController.text,
        reviewCount: _reviewCountController.text,
        category: _selectedCategory,
      );

      await FirebaseFirestore.instance.collection('books').add(newBook.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 등록 성공!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 도서 등록')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 이미지 선택 영역
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120, height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _pickedImage == null
                      ? const Icon(Icons.add_a_photo, size: 50)
                      : Image.file(_pickedImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),

              // 카테고리 선택
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'bestseller', child: Text('베스트셀러')),
                  DropdownMenuItem(value: 'recommend', child: Text('추천 Pick')),
                ],
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: '카테고리'),
              ),

              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: '제목'), validator: (v) => v!.isEmpty ? '입력해주세요' : null),
              TextFormField(controller: _authorController, decoration: const InputDecoration(labelText: '저자'), validator: (v) => v!.isEmpty ? '입력해주세요' : null),
              TextFormField(controller: _rankController, decoration: const InputDecoration(labelText: '순위 (예: 01)'), keyboardType: TextInputType.number),
              TextFormField(controller: _ratingController, decoration: const InputDecoration(labelText: '평점 (예: 4.8)'), keyboardType: TextInputType.number),
              TextFormField(controller: _reviewCountController, decoration: const InputDecoration(labelText: '리뷰 수 (예: 120)'), keyboardType: TextInputType.number),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveBook,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('도서 정보 저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}