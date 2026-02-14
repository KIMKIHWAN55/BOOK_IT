import 'package:flutter/material.dart';
import 'find_id_screen.dart';
import 'find_pw_screen.dart';
import '../controllers/auth_controller.dart';
// 🌟 방금 만든 공통 위젯 불러오기
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberId = true;

  Future<void> _handleEmailLogin() async {
    final errorMessage = await _authController.login(
        _emailController.text.trim(),
        _passwordController.text.trim()
    );

    if (mounted) {
      if (errorMessage == null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final errorMessage = await _authController.loginWithGoogle();
    if (mounted) {
      if (errorMessage == null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (errorMessage != 'cancel') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('로그인', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListenableBuilder(
          listenable: _authController,
          builder: (context, child) {
            return Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 80),
                        // 🌟 코드가 엄청 짧아졌죠?
                        CustomTextField(
                          hint: '아이디',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        CustomTextField(
                          hint: '비밀번호',
                          controller: _passwordController,
                          isObscure: true, // 비밀번호 숨김
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildRememberIdCheckbox(),
                            _buildFindAccountButtons(context),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // 🌟 메인 버튼도 단 세 줄로 끝!
                        PrimaryButton(
                          text: '로그인',
                          onPressed: _handleEmailLogin,
                          isLoading: _authController.isLoading,
                        ),
                        const SizedBox(height: 28),
                        _buildDividerWithText(),
                        const SizedBox(height: 28),
                        _buildSocialLoginButton(
                          text: '카카오로 시작하기', color: const Color(0xFFFEE500), textColor: const Color(0xFF222222), iconPath: '', onPressed: _authController.isLoading ? null : () {},
                        ),
                        const SizedBox(height: 16),
                        _buildSocialLoginButton(
                          text: '네이버로 시작하기', color: const Color(0xFF03C75A), textColor: Colors.white, iconPath: '', onPressed: _authController.isLoading ? null : () {},
                        ),
                        const SizedBox(height: 16),
                        _buildSocialLoginButton(
                          text: 'google로 시작하기', color: Colors.white, textColor: const Color(0xFF808080), iconPath: '', isOutlined: true, onPressed: _authController.isLoading ? null : _handleGoogleLogin,
                        ),
                        const SizedBox(height: 60),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('아직 회원이 아니신가요? ', style: TextStyle(fontSize: 14, color: Color(0xFF767676))),
                            GestureDetector(
                              onTap: () {
                                if (!_authController.isLoading) Navigator.pushNamed(context, '/signup');
                              },
                              child: const Text('회원가입', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD45858), decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_authController.isLoading)
                  Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
              ],
            );
          }
      ),
    );
  }

  // (아래는 자잘한 UI 함수들 그대로 유지)
  Widget _buildRememberIdCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberId = !_rememberId),
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _rememberId ? const Color(0xFFD45858) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _rememberId ? const Color(0xFFD45858) : Colors.grey),
            ),
            child: _rememberId ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ),
        const SizedBox(width: 8),
        const Text('아이디 저장', style: TextStyle(fontSize: 14, color: Color(0xFF767676))),
      ],
    );
  }

  Widget _buildFindAccountButtons(BuildContext context) {
    return Row(
      children: [
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindIdScreen())), child: const Text('아이디 찾기', style: TextStyle(color: Color(0xFF767676)))),
        const Text('|', style: TextStyle(color: Color(0xFFCBCBCB))),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindPwScreen())), child: const Text('비밀번호 찾기', style: TextStyle(color: Color(0xFF767676)))),
      ],
    );
  }

  Widget _buildDividerWithText() {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFF767676), thickness: 0.5)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('SNS 로그인', style: TextStyle(fontSize: 16, color: Color(0xFF767676)))),
        Expanded(child: Divider(color: Color(0xFF767676), thickness: 0.5)),
      ],
    );
  }

  Widget _buildSocialLoginButton({required String text, required Color color, required Color textColor, required String iconPath, VoidCallback? onPressed, bool isOutlined = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: textColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isOutlined ? const BorderSide(color: Color(0xFFC2C2C2)) : BorderSide.none), elevation: 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 16.0), child: const Icon(Icons.circle, size: 20))),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}