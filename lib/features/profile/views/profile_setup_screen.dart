import 'dart:io'; // 파일 처리를 위해 추가
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 스토리지 추가
import 'package:image_picker/image_picker.dart'; // 이미지 피커 추가
import '../../auth/views/signup_complete_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  File? _imageFile; // 갤러리에서 선택한 이미지 파일
  final ImagePicker _picker = ImagePicker();

  // 🔹 Pretendard 스타일 헬퍼
  TextStyle _ptStyle({
    required double size,
    required FontWeight weight,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.025 * size,
      height: 1.4,
    );
  }

  // 🔹 갤러리에서 이미지 선택 함수
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("이미지 선택 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("갤러리를 여는 도중 오류가 발생했습니다.")),
      );
    }
  }

  // 🔹 프로필 저장 로직 (이미지 업로드 포함)
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty || _nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이름과 닉네임은 필수 입력 항목입니다.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String profileImageUrl = '';

      // 1. 이미지가 선택되었다면 Firebase Storage에 업로드
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile_images')
            .child('${user.uid}.jpg'); // 유저 ID로 파일명 지정

        await storageRef.putFile(_imageFile!); // 업로드 실행
        profileImageUrl = await storageRef.getDownloadURL(); // 다운로드 URL 가져오기
      }

      // 2. Firestore에 회원 정보 저장
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'nickname': _nicknameController.text,
        'bio': _bioController.text,
        'profileImageUrl': profileImageUrl, // 업로드된 URL 저장 (없으면 빈 문자열)
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignupCompleteScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
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
        title: Text("프로필 설정", style: _ptStyle(size: 20, weight: FontWeight.w600, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text("안녕하세요 회원님", style: _ptStyle(size: 18, weight: FontWeight.w600, color: const Color(0xFF222222))),
            const SizedBox(height: 8),
            Text("회원님의 정보를 입력해 주세요", style: _ptStyle(size: 16, weight: FontWeight.w400, color: const Color(0xFF767676))),

            const SizedBox(height: 40),

            // 🌟 [수정됨] 프로필 사진 추가 영역
            GestureDetector(
              onTap: _pickImage, // 클릭 시 갤러리 오픈
              child: Column(
                children: [
                  Stack(
                    children: [
                      // 원형 이미지 표시
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFDFD),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                          image: _imageFile != null
                              ? DecorationImage(
                            image: FileImage(_imageFile!), // 선택한 사진 표시
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        // 사진 없을 때 기본 아이콘
                        child: _imageFile == null
                            ? const Center(child: Icon(Icons.person, size: 40, color: Color(0xFFCCCCCC)))
                            : null,
                      ),
                      // 카메라 아이콘
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF767676)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("프로필 사진 추가", style: _ptStyle(size: 12, weight: FontWeight.w600, color: const Color(0xFFD45858))),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 입력 폼
            _buildInputField(label: "이름", controller: _nameController, hintText: "이름을 입력해주세요"),
            const SizedBox(height: 24),
            _buildInputField(label: "닉네임", controller: _nicknameController, hintText: "닉네임을 입력해주세요 (2~20자 이내여야합니다)"),
            const SizedBox(height: 24),
            _buildInputField(label: "소개", controller: _bioController, hintText: "자기 소개 문구를 입력해 주세요"),

            const SizedBox(height: 60),

            // 다음 버튼
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD45858),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("다음", style: _ptStyle(size: 18, weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 입력 필드 빌더 (기존과 동일)
  Widget _buildInputField({required String label, required TextEditingController controller, required String hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
        ),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC2C2C2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            style: _ptStyle(size: 14, weight: FontWeight.w400, color: Colors.black),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFFC2C2C2)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}