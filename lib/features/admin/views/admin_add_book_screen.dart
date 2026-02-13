import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../book/models/book_model.dart';

class AdminAddBookScreen extends StatefulWidget {
  final BookModel? bookToEdit;

  const AdminAddBookScreen({super.key, this.bookToEdit});

  @override
  State<AdminAddBookScreen> createState() => _AdminAddBookScreenState();
}

class _AdminAddBookScreenState extends State<AdminAddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  // final TextEditingController _categoryController = TextEditingController(); // ❌ 기존 제거
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // 🌟 [추가] 선택된 카테고리 저장 변수
  String _selectedCategory = '';

  // 🌟 [추가] 카테고리 목록 (CategoryScreen과 통일)
  final List<String> _categoryList = [
    "로맨스", "무협", "추리", "공포/미스터리", "SF", "판타지",
    "금융/투자", "여행", "인간관계", "건강", "교재/수험서", "성공",
    "에세이/시", "철학", "심리", "동화", "예술",
    "한국사", "세계사", "종교", "정치", "사회", "경제",
    "요리", "육아", "스포츠", "취미", "청소년", "어린이"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.bookToEdit != null) {
      final book = widget.bookToEdit!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _rankController.text = book.rank;
      _selectedCategory = book.category; // 🌟 기존 카테고리 불러오기
      _descriptionController.text = book.description;
      _priceController.text = book.price.toString();
      _discountController.text = book.discountRate?.toString() ?? '';
      _tagsController.text = book.tags.join(', ');
    }
  }

  // ... (이미지 관련 함수 _pickImage, _uploadImageToStorage는 기존과 동일)
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<String> _uploadImageToStorage() async {
    if (_selectedImage == null) return '';
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_book_cover.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('book_covers/$fileName');
      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) { return ''; }
  }
  // ...

  Future<void> _registerBook() async {
    if (!_formKey.currentState!.validate()) return;

    // 🌟 카테고리 선택 검사
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요!')));
      return;
    }

    if (widget.bookToEdit == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 표지 이미지를 등록해주세요! 📷')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String downloadUrl;
      if (_selectedImage != null) {
        downloadUrl = await _uploadImageToStorage();
      } else {
        downloadUrl = widget.bookToEdit!.imageUrl;
      }

      // 🌟 [핵심 로직] 기존 태그 리스트에 '선택한 카테고리'도 자동으로 추가
      List<String> tagsList = _tagsController.text.isNotEmpty
          ? _tagsController.text.split(',').map((e) => e.trim()).toList()
          : [];

      // 카테고리를 태그에 없으면 추가 (중복 방지)
      if (!tagsList.contains(_selectedCategory)) {
        tagsList.add(_selectedCategory);
      }

      final newBook = BookModel(
        id: widget.bookToEdit?.id ?? '',
        title: _titleController.text,
        author: _authorController.text,
        imageUrl: downloadUrl,
        rank: _rankController.text,
        category: _selectedCategory, // 🌟 선택한 카테고리 저장
        rating: widget.bookToEdit?.rating ?? '0.0',
        reviewCount: widget.bookToEdit?.reviewCount ?? '0',
        description: _descriptionController.text,
        price: int.tryParse(_priceController.text) ?? 0,
        discountRate: int.tryParse(_discountController.text),
        tags: tagsList, // 🌟 카테고리가 포함된 태그 리스트 저장
      );

      if (widget.bookToEdit == null) {
        await FirebaseFirestore.instance.collection('books').add(newBook.toMap());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 등록 성공! 📚')));
      } else {
        await FirebaseFirestore.instance.collection('books').doc(widget.bookToEdit!.id).update(newBook.toMap());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 수정 완료! ✏️')));
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 [추가] 카테고리 선택 바텀 시트
  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("카테고리 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _categoryList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_categoryList[index]),
                      onTap: () {
                        setState(() {
                          _selectedCategory = _categoryList[index];
                        });
                        Navigator.pop(context);
                      },
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
    // ... (기존 build 상단 코드는 동일)
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
                  // ... (이미지 선택 위젯, 제목, 작가 필드는 기존 코드 유지)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120, height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200], borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : (isEditing && widget.bookToEdit!.imageUrl.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(widget.bookToEdit!.imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (_selectedImage == null && (!isEditing || widget.bookToEdit!.imageUrl.isEmpty))
                          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: Colors.grey, size: 40), SizedBox(height: 8), Text("표지 등록", style: TextStyle(color: Colors.grey))])
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_titleController, '책 제목', '예: Paradox'),
                  _buildTextField(_authorController, '작가', '예: 호베루투 카를로스'),

                  // 🌟 [수정] 순위와 카테고리 선택 UI
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_rankController, '순위', '예: 1', isNumber: true)),
                      const SizedBox(width: 16),
                      // 👇 CSS 스타일 적용된 카테고리 선택 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: _showCategorySelector,
                          child: Container(
                            height: 56, // TextField 높이와 얼추 맞춤
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFC2C2C2)), // CSS: border color
                              borderRadius: BorderRadius.circular(10), // CSS: border radius
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _selectedCategory.isEmpty ? "카테고리" : _selectedCategory,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                color: _selectedCategory.isEmpty ? const Color(0xFF767676) : Colors.black,
                                letterSpacing: -0.025,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ... (나머지 필드들 기존과 동일하게 유지)
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
                  _buildTextField(_tagsController, '추가 태그 (쉼표 구분)', '예: #인기, #신작'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: '줄거리', border: OutlineInputBorder(), hintText: '줄거리 입력'),
                  ),
                  const SizedBox(height: 30),

                  // 등록 버튼
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing ? Colors.orangeAccent : Colors.blueAccent,
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
          if (_isLoading) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  // _buildTextField 함수는 기존 유지
  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label, hintText: hint, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: (value) {
          if (label.contains('할인율') || label.contains('추가 태그')) return null;
          if (value == null || value.isEmpty) return '입력해주세요';
          return null;
        },
      ),
    );
  }
}