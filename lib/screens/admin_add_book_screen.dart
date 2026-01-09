import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:io'; // ◀ 이 줄이 있으면 웹에서 에러가 날 수 있으므로 절대 지워주세요.

class AdminAddBookScreen extends StatefulWidget {
  const AdminAddBookScreen({super.key});

  @override
  State<AdminAddBookScreen> createState() => _AdminAddBookScreenState();
}

class _AdminAddBookScreenState extends State<AdminAddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  Uint8List? _imageBytes; // 웹/앱 공용 이미지 바이트 데이터
  String? _fileName;
  bool _isLoading = false;

  // 이미지 선택 함수 (바이트 데이터 읽기 방식으로 통일)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // readAsBytes()는 웹과 모바일 모두에서 파일 데이터를 가져오는 표준 방식입니다.
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = pickedFile.name;
      });
    }
  }

  // 도서 등록 함수 (putData 방식으로 통일)
  Future<void> _uploadBook() async {
    if (!_formKey.currentState!.validate() || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지와 모든 정보를 입력해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Storage에 바이트 데이터로 업로드 (웹/앱 공용)
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('book_covers')
          .child('${DateTime.now().millisecondsSinceEpoch}_$_fileName');

      await storageRef.putData(_imageBytes!);
      final imageUrl = await storageRef.getDownloadURL();

      // 2. Firestore 저장
      await FirebaseFirestore.instance.collection('books').add({
        'title': _titleController.text,
        'author': _authorController.text,
        'description': _descriptionController.text,
        'price': int.tryParse(_priceController.text) ?? 0,
        'category': _categoryController.text,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록 성공!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도서 등록 (관리자)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200, width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                  ),
                  // ★ 핵심: Image.file을 절대 쓰지 말고 Image.memory만 사용합니다.
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : const Icon(Icons.camera_alt, size: 50),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: '제목')),
              TextFormField(controller: _authorController, decoration: const InputDecoration(labelText: '저자')),
              TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: '카테고리')),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: '가격'), keyboardType: TextInputType.number),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: '설명'), maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _uploadBook, child: const Text('저장하기')),
            ],
          ),
        ),
      ),
    );
  }
}