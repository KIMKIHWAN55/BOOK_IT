import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../book/models/book_model.dart';
import '../controllers/admin_controller.dart';
import '../repositories/admin_repository.dart';
import '../../../shared/widgets/custom_network_image.dart';

class AdminAddBookScreen extends ConsumerStatefulWidget {
  final BookModel? bookToEdit;

  const AdminAddBookScreen({super.key, this.bookToEdit});

  @override
  ConsumerState<AdminAddBookScreen> createState() => _AdminAddBookScreenState();
}

class _AdminAddBookScreenState extends ConsumerState<AdminAddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _rankController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _tagsController;

  File? _selectedImage;
  String? _fetchedImageUrl;
  final ImagePicker _picker = ImagePicker();

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
    _rankController = TextEditingController(text: book?.rank.toString() ?? '');
    _descriptionController = TextEditingController(text: book?.description ?? '');
    _priceController = TextEditingController(text: book?.price.toString() ?? '');
    _discountController = TextEditingController(text: book?.discountRate?.toString() ?? '');
    _tagsController = TextEditingController(text: book?.tags.join(', ') ?? '');
    _fetchedImageUrl = book?.imageUrl;

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
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _fetchedImageUrl = null;
      });
    }
  }

  // ====================================================================
  //  카카오 서버에 검색해서 빈칸 자동으로 채움
  // ====================================================================
  Future<void> _searchFromKakao() async {
    final query = _titleController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('검색할 책 제목을 먼저 입력해주세요.')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('카카오 서버에서 책 정보를 불러오는 중... 🔍')));

    FocusScope.of(context).unfocus();
    final result = await ref.read(adminRepositoryProvider).searchBookFromKakao(query);

    if (result != null) {
      setState(() {
        _titleController.text = result['title'] ?? _titleController.text;
        _authorController.text = (result['authors'] as List).join(', ');
        _descriptionController.text = result['contents'] ?? '';
        _priceController.text = result['price']?.toString() ?? '';

        // API로 이미지 가져온경우 내가 등록한 이미지는 삭제
        _fetchedImageUrl = result['thumbnail'];
        _selectedImage = null; // 기존 첨부 파일 초기화
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 정보 자동완성 완료! ✨')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('검색 결과가 없습니다.')));
    }
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요!')));
      return;
    }

    // 폰에서 직접 올린 사진도 없고, API로 가져온 URL도 없으면 차단
    if (_selectedImage == null && (_fetchedImageUrl == null || _fetchedImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책 표지 이미지를 등록하거나 검색해주세요! 📷')));
      return;
    }

    List<String> tagsList = _tagsController.text.isNotEmpty
        ? _tagsController.text.split(',').map((e) => e.trim()).toList()
        : [];

    if (!tagsList.contains(_selectedCategory)) {
      tagsList.add(_selectedCategory);
    }

    final tempBook = BookModel(
      id: widget.bookToEdit?.id ?? '',
      title: _titleController.text,
      author: _authorController.text,
      imageUrl: _fetchedImageUrl ?? '',
      rank: int.tryParse(_rankController.text) ?? 0,
      category: _selectedCategory,
      rating: widget.bookToEdit?.rating ?? '0.0',
      reviewCount: widget.bookToEdit?.reviewCount ?? '0',
      description: _descriptionController.text,
      price: int.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
      discountRate: int.tryParse(_discountController.text.replaceAll(',', '')),
      tags: tagsList,
    );

    final isEditing = widget.bookToEdit != null;

    final success = await ref.read(adminControllerProvider.notifier).registerBook(
      book: tempBook,
      newImage: _selectedImage, // 만약 새로 올린 사진이 있다면 이것만 업로드됨
      isEditing: isEditing,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? '책 수정 완료! ✏️' : '책 등록 성공! 📚')));
      Navigator.pop(context);
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
                        setState(() => _selectedCategory = _categoryList[index]);
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
    final adminState = ref.watch(adminControllerProvider);
    final isLoading = adminState.isLoading;
    final isEditing = widget.bookToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "책 수정하기" : "책 등록하기")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120, height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)

                            : (_fetchedImageUrl != null && _fetchedImageUrl!.isNotEmpty)
                            ? CustomNetworkImage(
                          imageUrl: _fetchedImageUrl!,
                          width: 120,
                          height: 180,
                        )
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text("표지 등록", style: TextStyle(color: Colors.grey))
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTextField(_titleController, '책 제목', '예: 데미안'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _searchFromKakao,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF21212F),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('API 검색', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  _buildTextField(_authorController, '작가', '예: 헤르만 헤세'),

                  Row(
                    children: [
                      Expanded(child: _buildTextField(_rankController, '순위', '예: 1 (선택)', isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showCategorySelector,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white, border: Border.all(color: const Color(0xFFC2C2C2)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _selectedCategory.isEmpty ? "카테고리" : _selectedCategory,
                              style: TextStyle(fontSize: 14, color: _selectedCategory.isEmpty ? const Color(0xFF767676) : Colors.black),
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

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing ? Colors.orangeAccent : Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isEditing ? "책 수정 완료" : "책 등록 완료", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
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
          if (label.contains('할인율') || label.contains('추가 태그') || label.contains('순위')) return null;
          if (value == null || value.isEmpty) return '입력해주세요';
          return null;
        },
      ),
    );
  }
}