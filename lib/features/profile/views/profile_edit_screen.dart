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

  // 🌟 [추가] 닉네임 중복 체크용 상태 변수들
  String _originalNickname = '';
  bool _isNicknameChecked = true; // 처음에는 원래 내 닉네임이므로 통과 상태

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await ref.read(profileActionControllerProvider).getRawProfileData();
      if (data != null && mounted) {
        setState(() {
          _nicknameController.text = data['nickname'] ?? '';
          _originalNickname = data['nickname'] ?? ''; // 내 원래 닉네임 기억
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _currentImageUrl = data['profileImage'];
        });
      }
    } catch (e) {
      print('데이터 로드 실패: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 🌟 [추가] 닉네임 중복 확인 로직
  Future<void> _checkDuplicate() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    if (nickname == _originalNickname) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('기존에 사용하시던 닉네임입니다.')));
      setState(() => _isNicknameChecked = true);
      return;
    }

    final isDuplicate = await ref.read(profileActionControllerProvider).checkNicknameDuplicate(nickname);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 사용 중인 닉네임입니다. 다른 닉네임을 입력해주세요.')));
      setState(() => _isNicknameChecked = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용 가능한 닉네임입니다!')));
      setState(() => _isNicknameChecked = true);
    }
  }

  Future<void> _saveProfile() async {
    // 🌟 [추가] 닉네임 중복 체크 안 했으면 튕겨내기
    if (!_isNicknameChecked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임 중복 확인을 해주세요!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(profileActionControllerProvider).updateProfile(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        bio: _bioController.text.trim(),
        imageFile: _imageFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필이 성공적으로 수정되었습니다.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: ${e.toString().replaceAll("Exception: ", "")}')));
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
        title: const Text('프로필 편집', style: TextStyle(fontFamily: 'Pretendard', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD45858)))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 30),
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
                    decoration: const BoxDecoration(color: Color(0xFFD45858), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: const Text('사진 변경하기', style: TextStyle(fontFamily: 'Pretendard', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD45858))),
            ),
            const SizedBox(height: 40),

            _buildCustomTextField(label: '이름', controller: _nameController),
            const SizedBox(height: 10),

            // 🌟 닉네임 입력란 (+ 중복 확인 버튼)
            _buildCustomTextField(
              label: '닉네임',
              controller: _nicknameController,
              // 글자가 바뀌면 다시 중복확인 하도록 상태 변경
              onChanged: (value) {
                if (value != _originalNickname) {
                  setState(() => _isNicknameChecked = false);
                } else {
                  setState(() => _isNicknameChecked = true);
                }
              },
              suffix: GestureDetector(
                onTap: _checkDuplicate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isNicknameChecked ? Colors.grey[300] : const Color(0xFF196DF8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isNicknameChecked ? '확인 완료' : '중복 확인',
                    style: TextStyle(
                      fontFamily: 'Pretendard', fontSize: 12, fontWeight: FontWeight.w600,
                      color: _isNicknameChecked ? Colors.black54 : Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            _buildCustomTextField(label: '소개', controller: _bioController),
            const SizedBox(height: 60),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD45858),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('변경 하기', style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🌟 suffix(우측 버튼)와 onChanged(타이핑 감지)를 받을 수 있도록 확장된 UI 위젯
  Widget _buildCustomTextField({
    required String label,
    required TextEditingController controller,
    Widget? suffix,
    Function(String)? onChanged,
  }) {
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
            child: Text(label, style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFF767676))),
          ),
          const VerticalDivider(color: Colors.transparent, width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Colors.black),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }
}