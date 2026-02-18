import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../book/models/book_model.dart';
import '../controllers/admin_controller.dart';

class AdminAddBookScreen extends ConsumerStatefulWidget {
  final BookModel? bookToEdit;

  const AdminAddBookScreen({super.key, this.bookToEdit});

  @override
  ConsumerState<AdminAddBookScreen> createState() => _AdminAddBookScreenState();
}

class _AdminAddBookScreenState extends ConsumerState<AdminAddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러들은 UI 요소이므로 그대로 둡니다.
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _rankController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _tagsController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // 선택된 카테고리
  String _selectedCategory = '';

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
    final book = widget.bookToEdit;

    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _rankController = TextEditingController(text: book?.rank ?? '');
    _descriptionController = TextEditingController(text: book?.description ?? '');
    _priceController = TextEditingController(text: book?.price.toString() ?? '');
    _discountController = TextEditingController(text: book?.discountRate?.toString() ?? '');
    _tagsController = TextEditingController(text: book?.tags.join(', ') ?? '');

    if (book != null) {
      _selectedCategory = book.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _rankController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // 카테고리 검사
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요!')));
      return;
    }

    // 이미지 검사 (새 등록일 때)
    if (widget.bookToEdit == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 표지 이미지를 등록해주세요! 📷')));
      return;
    }

    // 태그 리스트 생성 로직
    List<String> tagsList = _tagsController.text.isNotEmpty
        ? _tagsController.text.split(',').map((e) => e.trim()).toList()
        : [];

    if (!tagsList.contains(_selectedCategory)) {
      tagsList.add(_selectedCategory);
    }

    // 모델 생성 (이미지 URL은 Controller에서 처리)
    final tempBook = BookModel(
      id: widget.bookToEdit?.id ?? '',
      title: _titleController.text,
      author: _authorController.text,
      imageUrl: widget.bookToEdit?.imageUrl ?? '', // 기존 URL 혹은 빈 값
      rank: _rankController.text,
      category: _selectedCategory,
      rating: widget.bookToEdit?.rating ?? '0.0',
      reviewCount: widget.bookToEdit?.reviewCount ?? '0',
      description: _descriptionController.text,
      price: int.tryParse(_priceController.text) ?? 0,
      discountRate: int.tryParse(_discountController.text),
      tags: tagsList,
    );

    final isEditing = widget.bookToEdit != null;

    // Riverpod Controller 호출
    final success = await ref.read(adminControllerProvider.notifier).registerBook(
      book: tempBook,
      newImage: _selectedImage,
      isEditing: isEditing,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? '책 수정 완료! ✏️' : '책 등록 성공! 📚')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      // 에러 처리는 Controller state listener 혹은 여기서 간단히 처리
      final errorState = ref.read(adminControllerProvider);
      if (errorState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러 발생: ${errorState.error}')),
        );
      }
    }
  }

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
    // Riverpod 상태 구독 (로딩 체크용)
    final adminState = ref.watch(adminControllerProvider);
    final isLoading = adminState.isLoading;

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
                  // 이미지 선택 영역
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

                  // 순위 및 카테고리 선택 UI
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_rankController, '순위', '예: 1', isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showCategorySelector,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFC2C2C2)),
                              borderRadius: BorderRadius.circular(10),
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
                      onPressed: isLoading ? null : _submitForm,
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
          if (isLoading)
            Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: Colors.white))
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