import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 갤러리 이미지 선택
import 'package:firebase_storage/firebase_storage.dart'; // 이미지 업로드
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class AdminAddBookScreen extends StatefulWidget {
  final BookModel? bookToEdit; // 👈 수정할 책 데이터 (없으면 null = 신규 등록)

  const AdminAddBookScreen({super.key, this.bookToEdit});

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 🔹 [변경 1] 수정 모드(bookToEdit 있음)라면 기존 데이터를 컨트롤러에 채워 넣기
    if (widget.bookToEdit != null) {
      final book = widget.bookToEdit!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _rankController.text = book.rank;
      _categoryController.text = book.category;
      _descriptionController.text = book.description;
      _priceController.text = book.price.toString();
      _discountController.text = book.discountRate?.toString() ?? '';
      // 태그 리스트 -> 문자열 변환 (예: ['#SF', '#소설'] -> "#SF, #소설")
      _tagsController.text = book.tags.join(', ');
    }
  }

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
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_book_cover.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('book_covers/$fileName');

      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('이미지 업로드 실패: $e');
      return '';
    }
  }

  // 3. 책 등록/수정 함수 (이미지 업로드 -> Firestore 저장)
  Future<void> _registerBook() async {
    if (!_formKey.currentState!.validate()) return;

    // 🔹 [변경 2] 이미지 유효성 검사 수정
    // 신규 등록일 때는 이미지가 필수지만, 수정일 때는 기존 이미지를 쓰면 되므로 통과
    if (widget.bookToEdit == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('책 표지 이미지를 등록해주세요! 📷')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String downloadUrl;

      // 🔹 [변경 3] 이미지 URL 결정 로직
      if (_selectedImage != null) {
        // (A) 새 이미지를 선택함 -> 업로드 수행
        downloadUrl = await _uploadImageToStorage();
      } else {
        // (B) 새 이미지를 선택 안 함 -> 수정 모드라면 기존 URL 사용
        downloadUrl = widget.bookToEdit!.imageUrl;
      }

      if (downloadUrl.isEmpty) {
        throw Exception("이미지 처리에 실패했습니다.");
      }

      List<String> tagsList = _tagsController.text.isNotEmpty
          ? _tagsController.text.split(',').map((e) => e.trim()).toList()
          : [];

      // 모델 생성
      final newBook = BookModel(
        // 수정 시에는 기존 ID 유지, 신규 시에는 빈 문자열(add할 때 자동생성됨, 혹은 모델 구조에 따라 처리)
        id: widget.bookToEdit?.id ?? '',
        title: _titleController.text,
        author: _authorController.text,
        imageUrl: downloadUrl,
        rank: _rankController.text,
        category: _categoryController.text,
        // 기존 평점/리뷰수는 유지 (없으면 초기값)
        rating: widget.bookToEdit?.rating ?? '0.0',
        reviewCount: widget.bookToEdit?.reviewCount ?? '0',
        description: _descriptionController.text,
        price: int.tryParse(_priceController.text) ?? 0,
        discountRate: int.tryParse(_discountController.text),
        tags: tagsList,
      );

      // 🔹 [변경 4] Firestore 저장 로직 분기 (Add vs Update)
      if (widget.bookToEdit == null) {
        // [신규 등록]
        await FirebaseFirestore.instance.collection('books').add(newBook.toMap());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 등록 성공! 📚')));
      } else {
        // [수정 하기] - doc(id)를 지정하여 update
        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.bookToEdit!.id)
            .update(newBook.toMap());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 수정 완료! ✏️')));
      }

      if (!mounted) return;
      Navigator.pop(context); // 이전 화면으로 돌아가기

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 화면 제목 및 버튼 텍스트 조건부 설정
    final isEditing = widget.bookToEdit != null;
    final appBarTitle = isEditing ? "책 수정하기 (관리자)" : "책 등록하기 (관리자)";
    final buttonText = isEditing ? "책 수정 완료" : "책 등록 완료";

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Stack(
        children: [
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
                        // 🔹 [변경 5] 수정 모드일 때 선택된 파일이 없으면 기존 네트워크 이미지 표시
                            : (isEditing && widget.bookToEdit!.imageUrl.isNotEmpty)
                            ? DecorationImage(
                          image: NetworkImage(widget.bookToEdit!.imageUrl),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: (_selectedImage == null && (!isEditing || widget.bookToEdit!.imageUrl.isEmpty))
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
                        backgroundColor: isEditing ? Colors.orangeAccent : Colors.blueAccent, // 수정 모드면 색상 변경 (선택)
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(buttonText, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

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
          // 순위 등 숫자 필드는 필수 체크
          if (value == null || value.isEmpty) {
            // 할인율 등 선택사항일 수 있는 것은 제외하려면 여기서 조건 조정 필요 (현재 코드는 전체 필수)
            if (label.contains('할인율')) return null; // 할인율은 비워도 되면 리턴 null
            return '입력해주세요';
          }
          return null;
        },
      ),
    );
  }
}