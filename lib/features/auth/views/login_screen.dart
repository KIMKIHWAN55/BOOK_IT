import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'find_id_screen.dart';
import 'find_pw_screen.dart';
import '../controllers/auth_controller.dart';
// 🌟 커스텀 위젯 임포트 (경로 확인 완료)
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

  // 이메일 로그인 로직
  Future<void> _handleEmailLogin() async {
    final errorMessage = await ref.read(authControllerProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (errorMessage == null) {
        Navigator.pushReplacementNamed(context, '/main'); // 메인 화면으로 이동
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  // 구글 로그인 로직
  Future<void> _handleGoogleLogin() async {
    final errorMessage = await ref.read(authControllerProvider.notifier).loginWithGoogle();

    if (mounted) {
      if (errorMessage == null) {
        Navigator.pushReplacementNamed(context, '/main');
      } else if (errorMessage != 'cancel') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 상태 구독
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('로그인', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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

                  // 🌟 [교체 완료] 아이디 입력창
                  // CustomTextField 내부에 padding-bottom: 24가 있어서 별도 SizedBox 불필요
                  CustomTextField(
                    controller: _emailController,
                    hint: '아이디',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // 🌟 [교체 완료] 비밀번호 입력창
                  CustomTextField(
                    controller: _passwordController,
                    hint: '비밀번호',
                    isObscure: true, // 비밀번호 가리기
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRememberIdCheckbox(),
                      _buildFindAccountButtons(context),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🌟 [교체 완료] 메인 로그인 버튼
                  // 로딩 중일 때 로딩 인디케이터가 버튼 안에 표시됨
                  PrimaryButton(
                    text: '로그인',
                    onPressed: _handleEmailLogin,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 28),
                  _buildDividerWithText(),
                  const SizedBox(height: 28),

                  // SNS 로그인 버튼들
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
                      const Text('아직 회원이 아니신가요? ', style: TextStyle(fontSize: 14, color: Color(0xFF767676))),
                      GestureDetector(
                        onTap: () {
                          if (!isLoading) Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text('회원가입', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD45858), decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // 전체 화면 터치 막기용 투명 오버레이 (선택 사항)
          // PrimaryButton이 자체적으로 로딩 처리를 하지만, SNS 버튼 등 다른 곳 터치를 막으려면 두는 게 좋습니다.
          if (isLoading)
            Container(
              color: Colors.transparent, // 배경을 어둡게 하지 않고 투명하게 막기만 함 (버튼 로딩이 보이니까)
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
              color: _rememberId ? const Color(0xFFD45858) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _rememberId ? const Color(0xFFD45858) : Colors.grey),
            ),
            child: _rememberId ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 8),
          const Text('아이디 저장', style: TextStyle(fontSize: 14, color: Color(0xFF767676))),
        ],
      ),
    );
  }

  Widget _buildFindAccountButtons(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindIdScreen())),
          child: const Text('아이디 찾기', style: TextStyle(color: Color(0xFF767676))),
        ),
        const Text('|', style: TextStyle(color: Color(0xFFCBCBCB))),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindPwScreen())),
          child: const Text('비밀번호 찾기', style: TextStyle(color: Color(0xFF767676))),
        ),
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
          side: isOutlined ? const BorderSide(color: Color(0xFFC2C2C2)) : BorderSide.none,
        ),
        elevation: 0,
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}