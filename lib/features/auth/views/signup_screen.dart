import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/signup_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart'; //
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();

  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : null,
      ));
    }
  }

  Future<void> _handleCheckEmail() async {
    final error = await ref.read(signupControllerProvider.notifier).checkEmailDuplicate(_emailController.text);
    if (error != null) _showSnackBar(error);
    else _showSnackBar("사용 가능한 이메일입니다.", isSuccess: true);
  }

  Future<void> _handleCheckNickname() async {
    final error = await ref.read(signupControllerProvider.notifier).checkNicknameDuplicate(_nicknameController.text);
    if (error != null) _showSnackBar(error);
    else _showSnackBar("사용 가능한 닉네임입니다.", isSuccess: true);
  }

  Future<void> _handleSendVerification() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim();
    final phone = _phoneController.text.trim();

    final errorMessage = await ref.read(signupControllerProvider.notifier).requestVerification(
      email: email,
      password: password,
      passwordConfirm: _passwordConfirmController.text.trim(),
      name: name,
      nickname: nickname,
      phone: phone,
    );

    if (mounted) {
      if (errorMessage == null) {
        Navigator.pushNamed(
          context,
          AppRouter.verification,
          arguments: {
            'email': email,
            'password': password,
            'name': name,
            'nickname': nickname,
            'phone': phone,
          },
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
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupControllerProvider);

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

                  CustomTextField(
                    label: '이메일 (ID)',
                    hint: 'ID로 사용할 이메일을 입력해 주세요',
                    icon: Icons.person_outline,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => ref.read(signupControllerProvider.notifier).resetEmailCheck(),
                    suffixButton: ElevatedButton(
                      onPressed: signupState.isEmailVerified ? null : _handleCheckEmail,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: signupState.isEmailVerified ? Colors.grey : AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      child: Text(signupState.isEmailVerified ? '확인됨' : '중복확인', style: const TextStyle(color: Colors.white)),
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

                  CustomTextField(
                    label: '닉네임',
                    hint: '닉네임을 입력해주세요 (2~20자 이내)',
                    controller: _nicknameController,
                    onChanged: (_) => ref.read(signupControllerProvider.notifier).resetNicknameCheck(),
                    suffixButton: ElevatedButton(
                      onPressed: signupState.isNicknameVerified ? null : _handleCheckNickname,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: signupState.isNicknameVerified ? Colors.grey : AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      child: Text(signupState.isNicknameVerified ? '확인됨' : '중복확인', style: const TextStyle(color: Colors.white)),
                    ),
                  ),

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
            if (signupState.isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PrimaryButton(
            text: '이메일로 본인 인증하기',
            onPressed: _handleSendVerification,
            isLoading: signupState.isLoading,
          ),
        ),
      ),
    );
  }
}