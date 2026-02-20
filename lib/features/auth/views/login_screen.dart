import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
// 🌟 우리가 만든 라우터와 색상 테마 임포트
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberId = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// 🌟 이메일 로그인 로직
  Future<void> _handleEmailLogin() async {
    // 1. 로그인 버튼 누르면 키보드부터 깔끔하게 내리기 (아까 본 로그 방지)
    FocusScope.of(context).unfocus();

    final errorMessage = await ref.read(authControllerProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return; // 화면이 닫혔으면 중단

    if (errorMessage != null) {
      // 2. 에러가 났을 때 스낵바 띄우기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      // 🌟 3. [추가됨] 로그인이 성공(errorMessage == null)하면 메인 화면으로 강제 이동!
      // 이전 인증 화면들을 싹 지우고(pushNamedAndRemoveUntil) 메인으로 갑니다.
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.main, (route) => false);
    }
  }

  // 🌟 구글 로그인 로직
  Future<void> _handleGoogleLogin() async {
    // 구글 로그인창 뜨기 전에 키보드 내리기
    FocusScope.of(context).unfocus();

    final errorMessage = await ref.read(authControllerProvider.notifier).loginWithGoogle();

    if (!mounted) return; // 화면이 닫혔으면 중단

    if (errorMessage != null && errorMessage != 'cancel') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else if (errorMessage == null) {
      // 🌟 [추가됨] 구글 로그인 성공 시 메인 화면으로 강제 이동!
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.main, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 1. 로딩 상태 구독 (bool 타입을 직접 받음!)
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('로그인', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),

                  CustomTextField(
                    controller: _emailController,
                    hint: '아이디',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  CustomTextField(
                    controller: _passwordController,
                    hint: '비밀번호',
                    isObscure: true,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRememberIdCheckbox(),
                      _buildFindAccountButtons(context),
                    ],
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: '로그인',
                    onPressed: _handleEmailLogin,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 28),
                  _buildDividerWithText(),
                  const SizedBox(height: 28),

                  _buildSocialLoginButton(
                    text: '카카오로 시작하기',
                    color: const Color(0xFFFEE500),
                    textColor: const Color(0xFF222222),
                    onPressed: isLoading ? null : () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('카카오 로그인은 아직 준비 중입니다.')));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSocialLoginButton(
                    text: '네이버로 시작하기',
                    color: const Color(0xFF03C75A),
                    textColor: Colors.white,
                    onPressed: isLoading ? null : () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('네이버 로그인은 아직 준비 중입니다.')));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSocialLoginButton(
                    text: 'Google로 시작하기',
                    color: Colors.white,
                    textColor: const Color(0xFF808080),
                    isOutlined: true,
                    onPressed: isLoading ? null : _handleGoogleLogin,
                  ),

                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('아직 회원이 아니신가요? ', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
                      GestureDetector(
                        // 🌟 3. AppRouter 적용
                        onTap: () {
                          if (!isLoading) Navigator.pushNamed(context, AppRouter.signup);
                        },
                        child: const Text('회원가입', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
        ],
      ),
    );
  }

  // --- 하위 위젯 헬퍼 함수들 ---

  Widget _buildRememberIdCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _rememberId = !_rememberId),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _rememberId ? AppColors.primary : Colors.transparent, // 🌟 색상 변경
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _rememberId ? AppColors.primary : AppColors.border),
            ),
            child: _rememberId ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 8),
          const Text('아이디 저장', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
        ],
      ),
    );
  }

  Widget _buildFindAccountButtons(BuildContext context) {
    return Row(
      children: [
        TextButton(
          // 🌟 3. AppRouter 적용
          onPressed: () => Navigator.pushNamed(context, AppRouter.findId),
          child: const Text('아이디 찾기', style: TextStyle(color: AppColors.textSub)),
        ),
        const Text('|', style: TextStyle(color: AppColors.border)),
        TextButton(
          // 🌟 3. AppRouter 적용
          onPressed: () => Navigator.pushNamed(context, AppRouter.findPw),
          child: const Text('비밀번호 찾기', style: TextStyle(color: AppColors.textSub)),
        ),
      ],
    );
  }

  Widget _buildDividerWithText() {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppColors.border, thickness: 1.0)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('SNS 로그인', style: TextStyle(fontSize: 14, color: AppColors.textSub))),
        Expanded(child: Divider(color: AppColors.border, thickness: 1.0)),
      ],
    );
  }

  Widget _buildSocialLoginButton({
    required String text,
    required Color color,
    required Color textColor,
    VoidCallback? onPressed,
    bool isOutlined = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isOutlined ? const BorderSide(color: AppColors.border) : BorderSide.none,
        ),
        elevation: 0,
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}