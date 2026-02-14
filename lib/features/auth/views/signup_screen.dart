import 'package:flutter/material.dart';
import 'verification_screen.dart';
import '../controllers/signup_controller.dart';
import '../../../core/constants/app_colors.dart'; // 🌟 AppColors 추가
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SignupController _signupController = SignupController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController(); // 🌟 휴대폰 컨트롤러 추가

  // 🌟 스낵바 띄우는 공통 함수 (성공 시 초록색 알림)
  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : null,
      ));
    }
  }

  // 🌟 이메일 중복 확인 로직
  Future<void> _handleCheckEmail() async {
    final error = await _signupController.checkEmailDuplicate(_emailController.text);
    if (error != null) _showSnackBar(error);
    else _showSnackBar("사용 가능한 이메일입니다.", isSuccess: true);
  }

  // 🌟 닉네임 중복 확인 로직
  Future<void> _handleCheckNickname() async {
    final error = await _signupController.checkNicknameDuplicate(_nicknameController.text);
    if (error != null) _showSnackBar(error);
    else _showSnackBar("사용 가능한 닉네임입니다.", isSuccess: true);
  }

  // 본인 인증 버튼 로직
  Future<void> _handleSendVerification() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim();
    final phone = _phoneController.text.trim(); // 🌟 휴대폰 번호 가져오기

    // 🌟 requestVerification에 phone 파라미터 추가
    final errorMessage = await _signupController.requestVerification(
      email: email,
      password: password,
      passwordConfirm: _passwordConfirmController.text.trim(),
      name: name,
      nickname: nickname,
      phone: phone,
    );

    if (mounted) {
      if (errorMessage == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              email: email,
              password: password,
              name: name,
              nickname: nickname,
              phone: phone, // 🌟 다음 화면(VerificationScreen)으로 phone 전달
            ),
          ),
        );
      } else {
        _showSnackBar(errorMessage);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose(); // 🌟 dispose 추가
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListenableBuilder(
          listenable: _signupController,
          builder: (context, child) {
            return SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // 🌟 이메일 (중복확인 버튼 부착)
                        CustomTextField(
                          label: '이메일 (ID)',
                          hint: 'ID로 사용할 이메일을 입력해 주세요',
                          icon: Icons.person_outline,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => _signupController.resetEmailCheck(), // 텍스트 수정 시 초기화
                          suffixButton: ElevatedButton(
                            onPressed: _signupController.isEmailVerified ? null : _handleCheckEmail,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _signupController.isEmailVerified ? Colors.grey : AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            child: Text(_signupController.isEmailVerified ? '확인됨' : '중복확인', style: const TextStyle(color: Colors.white)),
                          ),
                        ),

                        CustomTextField(
                          label: '비밀번호',
                          hint: '비밀번호를 입력해주세요 (최소 8자 이상)',
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                          isObscure: true,
                        ),

                        CustomTextField(
                          label: '비밀번호 확인',
                          hint: '비밀번호를 확인해주세요',
                          icon: Icons.lock_outline,
                          controller: _passwordConfirmController,
                          isObscure: true,
                        ),

                        CustomTextField(
                          label: '이름',
                          hint: '이름을 입력해주세요',
                          controller: _nameController,
                        ),

                        // 🌟 닉네임 (중복확인 버튼 부착)
                        CustomTextField(
                          label: '닉네임',
                          hint: '닉네임을 입력해주세요 (2~20자 이내)',
                          controller: _nicknameController,
                          onChanged: (_) => _signupController.resetNicknameCheck(), // 텍스트 수정 시 초기화
                          suffixButton: ElevatedButton(
                            onPressed: _signupController.isNicknameVerified ? null : _handleCheckNickname,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _signupController.isNicknameVerified ? Colors.grey : AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            child: Text(_signupController.isNicknameVerified ? '확인됨' : '중복확인', style: const TextStyle(color: Colors.white)),
                          ),
                        ),

                        // 🌟 휴대폰 번호 (새로 추가됨: 아이디 찾기 용도)
                        CustomTextField(
                            label: '휴대폰 번호',
                            hint: '- 없이 숫자만 입력',
                            icon: Icons.phone_iphone,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                  if (_signupController.isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                ],
              ),
            );
          }
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListenableBuilder(
              listenable: _signupController,
              builder: (context, child) {
                return PrimaryButton(
                  text: '이메일로 본인 인증하기',
                  onPressed: _handleSendVerification,
                  isLoading: _signupController.isLoading,
                );
              }
          ),
        ),
      ),
    );
  }
}