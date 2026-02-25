import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/views/signup_complete_screen.dart';
import '../../auth/services/auth_service.dart';
import '../controllers/profile_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isDataLoading = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  Future<void> _loadInitialUserData() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _nicknameController.text = data['nickname'] ?? '';
          _isDataLoading = false;
        });
      }
    }
  }

  TextStyle _ptStyle({required double size, required FontWeight weight, required Color color}) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.025 * size,
      height: 1.4,
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("갤러리를 여는 도중 오류가 발생했습니다.")));
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이름과 닉네임은 필수입니다.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(profileActionControllerProvider).setupProfile(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        bio: _bioController.text.trim(),
        imageFile: _imageFile,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignupCompleteScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("오류 발생: ${e.toString().replaceAll('Exception: ', '')}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 데이터 로딩 중이면 인디케이터 표시
    if (_isDataLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("프로필 설정", style: _ptStyle(size: 20, weight: FontWeight.w600, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text("거의 다 왔어요!", style: _ptStyle(size: 18, weight: FontWeight.w600, color: const Color(0xFF222222))),
            const SizedBox(height: 8),
            Text("나를 표현하는 사진과 소개를 더해 보세요", style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),

            const SizedBox(height: 40),

            //  프로필 사진
            _buildImagePickerSection(),

            const SizedBox(height: 50),

            //가입 정보 확인
            _buildInputField(label: "이름", controller: _nameController, hintText: "이름", isReadOnly: true), // 이름은 웬만하면 고정
            const SizedBox(height: 24),
            _buildInputField(label: "닉네임", controller: _nicknameController, hintText: "닉네임을 입력해주세요"),
            const SizedBox(height: 24),

            //소개글 입력
            _buildInputField(label: "소개글", controller: _bioController, hintText: "나를 한 줄로 소개해 주세요", maxLines: 3),

            const SizedBox(height: 60),

            // 완료 버튼
            _buildSubmitButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                  image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                ),
                child: _imageFile == null ? const Icon(Icons.person, size: 50, color: Color(0xFFCCCCCC)) : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFFD45858), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("사진 업로드", style: _ptStyle(size: 14, weight: FontWeight.w600, color: const Color(0xFFD45858))),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    bool isReadOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _ptStyle(size: 14, weight: FontWeight.w500, color: const Color(0xFF767676))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly,
          style: _ptStyle(size: 15, weight: FontWeight.w400, color: isReadOnly ? Colors.grey : Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isReadOnly ? const Color(0xFFF9F9F9) : Colors.white,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E5E5))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD45858))),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD45858),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text("완료하기", style: _ptStyle(size: 18, weight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}