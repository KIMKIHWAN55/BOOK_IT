import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 선택
import 'package:firebase_storage/firebase_storage.dart'; // 이미지 저장
import 'package:cloud_firestore/cloud_firestore.dart'; // 데이터 저장
import 'package:firebase_auth/firebase_auth.dart';


class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _imageFile; // 갤러리에서 선택한 이미지 파일
  String? _currentImageUrl; // 현재 설정된 이미지 URL
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 기존 사용자 정보 불러오기
  Future<void> _loadUserData() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nicknameController.text = data['nickname'] ?? '';
          _nameController.text = data['name'] ?? ''; // DB에 name 필드가 있다면 로드
          _bioController.text = data['bio'] ?? '';   // DB에 bio 필드가 있다면 로드
          _currentImageUrl = data['profileImage'];
        });
      }
    } catch (e) {
      print('데이터 로드 실패: $e');
    }
  }

  // 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 프로필 저장 (이미지 업로드 -> URL 획득 -> Firestore 업데이트)
  Future<void> _saveProfile() async {
    if (_user == null) return;
    setState(() => _isLoading = true);

    try {
      String? downloadUrl = _currentImageUrl;

      // 1. 이미지가 변경되었다면 Storage에 업로드
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile')
            .child('${_user!.uid}.jpg'); // 파일명: uid.jpg

        await storageRef.putFile(_imageFile!);
        downloadUrl = await storageRef.getDownloadURL();
      }

// 2. Firestore 정보 업데이트 (안전하게 저장)
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'bio': _bioController.text.trim(), // 소개글
        // 이미지가 변경되었을 때만(null이 아닐 때만) profileImage 필드를 업데이트
        if (downloadUrl != null) 'profileImage': downloadUrl,
      }, SetOptions(merge: true)); // ★ 중요: 기존 데이터(이메일 등)는 살려두고 덮어쓰기

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 성공적으로 수정되었습니다.')),
        );
        Navigator.pop(context); // 저장 후 뒤로가기
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
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

            // --- 프로필 이미지 영역 (CSS 기반) ---
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // 이미지 원형
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

                  // 카메라 아이콘 (빨간 원)
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 5, bottom: 5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD45858), // 빨간색 포인트
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // "사진 변경하기" 텍스트
            GestureDetector(
              onTap: _pickImage,
              child: const Text(
                '사진 변경하기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD45858), // 포인트 컬러
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
                  backgroundColor: const Color(0xFFD45858), // 버튼 색상
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

  // 커스텀 텍스트 필드 위젯 (CSS 스타일 적용)
  Widget _buildCustomTextField({required String label, required TextEditingController controller}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC2C2C2)), // 테두리 색상
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 라벨 (이름, 닉네임, 소개)
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Color(0xFF767676), // 글자 색상
              ),
            ),
          ),
          const VerticalDivider(color: Colors.transparent, width: 10), // 간격
          // 입력창
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