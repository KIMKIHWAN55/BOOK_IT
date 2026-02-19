import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/profile_controller.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Controller를 통해 기존 사용자 정보 불러오기
  Future<void> _loadUserData() async {
    try {
      final data = await ref.read(profileActionControllerProvider).getRawProfileData();
      if (data != null && mounted) {
        setState(() {
          _nicknameController.text = data['nickname'] ?? '';
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _currentImageUrl = data['profileImage'];
        });
      }
    } catch (e) {
      print('데이터 로드 실패: $e');
    }
  }

  // 갤러리에서 이미지 선택 (UI 역할이므로 View에 유지)
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 프로필 저장 액션
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      // Storage 업로드와 Firestore 업데이트를 Controller가 알아서 처리
      await ref.read(profileActionControllerProvider).updateProfile(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        bio: _bioController.text.trim(),
        imageFile: _imageFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 성공적으로 수정되었습니다.')),
        );
        Navigator.pop(context); // 저장 후 뒤로가기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '프로필 편집',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD45858)))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // --- 프로필 이미지 영역 ---
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      shape: BoxShape.circle,
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                          : null),
                    ),
                    child: (_imageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 5, bottom: 5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD45858),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickImage,
              child: const Text(
                '사진 변경하기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD45858),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- 입력 필드들 ---
            _buildCustomTextField(label: '이름', controller: _nameController),
            const SizedBox(height: 10),
            _buildCustomTextField(label: '닉네임', controller: _nicknameController),
            const SizedBox(height: 10),
            _buildCustomTextField(label: '소개', controller: _bioController),

            const SizedBox(height: 60),

            // --- 변경하기 버튼 ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD45858),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '변경 하기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({required String label, required TextEditingController controller}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC2C2C2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Color(0xFF767676),
              ),
            ),
          ),
          const VerticalDivider(color: Colors.transparent, width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}