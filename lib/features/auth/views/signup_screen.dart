import 'package:bookit_app/features/auth/views/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isLoading = false;

  // 이메일 인증 코드 발송 요청 함수
  Future<void> _sendVerificationCode() async {
    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // ❗ 실제 Cloud Function URL로 교체해야 합니다.
      final url = Uri.parse('https://sendverificationcode-o4apuahgma-uc.a.run.app');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
                name: _nameController.text.trim(),
                nickname: _nicknameController.text.trim(),
              ),
            ),
          );
        }
      } else {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('인증 코드 발송에 실패했습니다: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI 코드는 변경 없음 (이전과 동일)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('회원가입', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildTextField(label: '이메일 (ID)', hint: 'ID로 사용할 이메일을 입력해 주세요', icon: Icons.person_outline, controller: _emailController, keyboardType: TextInputType.emailAddress),
                  _buildTextField(label: '비밀번호', hint: '비밀번호를 입력해주세요 (최소 8자 이상)', icon: Icons.lock_outline, controller: _passwordController, isObscure: true),
                  _buildTextField(label: '비밀번호 확인', hint: '비밀번호를 확인해주세요', icon: Icons.lock_outline, controller: _passwordConfirmController, isObscure: true),
                  _buildTextField(label: '이름', hint: '이름을 입력해주세요', controller: _nameController),
                  _buildTextField(label: '닉네임', hint: '닉네임을 입력해주세요 (2~20자 이내)', controller: _nicknameController),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD45858),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('이메일로 본인 인증하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF767676), fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isObscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF767676)),
              prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF767676)) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFC2C2C2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFC2C2C2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

