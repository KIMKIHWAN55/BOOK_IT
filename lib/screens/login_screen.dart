import 'package:flutter/foundation.dart' show kIsWeb; // 웹 플랫폼 확인을 위해 import
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 구글 로그인 패키지 import
import 'package:bookit_app/screens/find_id_screen.dart';
import 'package:bookit_app/screens/find_pw_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberId = true;

  // 이메일/비밀번호 로그인 함수
  Future<void> _signIn() async {
    setState(() { _isLoading = true; });
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이메일 또는 비밀번호가 올바르지 않습니다.')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 구글 로그인 함수
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 웹 플랫폼일 경우
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await _auth.signInWithPopup(provider);
      } else {
        // 모바일 플랫폼일 경우
        await _googleSignIn.signOut().catchError((_) {});

        // UI로 인증 시작 (signIn() 대신 authenticate() 사용)
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

        // 사용자가 취소한 경우
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return;
        }

        // 인증 정보로부터 idToken 가져오기
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // idToken만 사용하여 Firebase credential 생성 (accessToken 없음)
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        // Firebase에 최종 로그인
        await _auth.signInWithCredential(credential);
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 로그인에 실패했습니다: $e')),
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
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: '아이디',
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '비밀번호',
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRememberIdCheckbox(),
                      _buildFindAccountButtons(context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD45858),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 28),
                  _buildDividerWithText(),
                  const SizedBox(height: 28),
                  _buildSocialLoginButton(
                      text: '카카오로 시작하기',
                      color: const Color(0xFFFEE500),
                      textColor: const Color(0xFF222222),
                      iconPath: 'assets/images/kakao_icon.png',
                      onPressed: _isLoading ? null : () { /* TODO: 카카오 로그인 연동 */ }
                  ),
                  const SizedBox(height: 16),
                  _buildSocialLoginButton(
                      text: '네이버로 시작하기',
                      color: const Color(0xFF03C75A),
                      textColor: Colors.white,
                      iconPath: 'assets/images/naver_icon.png',
                      onPressed: _isLoading ? null : () { /* TODO: 네이버 로그인 연동 */ }
                  ),
                  const SizedBox(height: 16),
                  _buildSocialLoginButton(
                    text: 'google로 시작하기',
                    color: Colors.white,
                    textColor: const Color(0xFF808080),
                    iconPath: 'assets/images/google_icon.png',
                    isOutlined: true,
                    onPressed: _isLoading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 60),
                  // ★★★★★ 이 부분이 요청하신 코드로 교체되었습니다 ★★★★★
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('아직 회원이 아니신가요? ', style: TextStyle(fontSize: 14, color: Color(0xFF767676))),
                      GestureDetector(
                        // 🔸 onTap 로직 수정
                        onTap: () {
                          // 로딩 중이 아닐 때만 회원가입 화면으로 이동
                          if (!_isLoading) {
                            Navigator.pushNamed(context, '/signup');
                          }
                        },
                        child: const Text('회원가입',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD45858),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildRememberIdCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberId = !_rememberId),
          child: Container(
            width: 22,
            height: 22,
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

// --- 기존의 _buildFindAccountButtons()를 아래 코드로 교체합니다 ---
  Widget _buildFindAccountButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. 아이디 찾기 버튼
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FindIdScreen()),
            );
          },
          child: const Text(
            '아이디 찾기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Color(0xFF767676),
            ),
          ),
        ),

        // 2. 중간 구분선
        const Text(
          '|',
          style: TextStyle(color: Color(0xFFCBCBCB)),
        ),

        // 3. 비밀번호 찾기 버튼
        TextButton(
          onPressed: () {
            // 🔸 FindPwScreen으로 이동하도록 연결됨
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FindPwScreen()),
            );
          },
          child: const Text(
            '비밀번호 찾기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Color(0xFF767676),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDividerWithText() {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFF767676), thickness: 0.5)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('SNS 로그인', style: TextStyle(fontSize: 16, color: Color(0xFF767676))),
        ),
        Expanded(child: Divider(color: Color(0xFF767676), thickness: 0.5)),
      ],
    );
  }

  Widget _buildSocialLoginButton({
    required String text,
    required Color color,
    required Color textColor,
    required String iconPath,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: const Icon(Icons.circle, size: 20), // 임시 아이콘
            ),
          ),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

