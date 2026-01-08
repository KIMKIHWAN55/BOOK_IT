import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FindPwScreen extends StatefulWidget {
  const FindPwScreen({super.key});

  @override
  State<FindPwScreen> createState() => _FindPwScreenState();
}

class _FindPwScreenState extends State<FindPwScreen> {
  int _currentStep = 1;
  bool _isLoading = false;

  // 🔸 이름 컨트롤러 추가
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  TextStyle _ptStyle({required double size, required FontWeight weight, Color color = const Color(0xFF222222)}) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
      letterSpacing: size * -0.025,
    );
  }

// 🔸 [수정된 로직] 이메일 인증번호 발송 함수
  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar("이메일을 입력해주세요.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. [해결] 인스턴스가 아닌 클래스명(EmailOTP)으로 설정
      EmailOTP.config(
        appName: "Bookit App",
        otpLength: 4,
        otpType: OTPType.numeric, // digitsOnly 대신 numeric 사용
      );

      // 2. [해결] 필수 파라미터인 email을 포함하여 발송
      bool result = await EmailOTP.sendOTP(
        email: _emailController.text.trim(),
      );

      if (result) {
        _showSnackBar("인증번호가 발송되었습니다.");
        setState(() => _currentStep = 2);
      } else {
        _showSnackBar("인증번호 발송에 실패했습니다.");
      }
    } catch (e) {
      // 3. 마지막 스크린샷의 에러 원인을 파악하기 위해 로그 출력
      debugPrint("발송 에러 상세: $e");
      _showSnackBar("오류가 발생했습니다. 이메일 형식을 확인해주세요.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔸 [수정된 로직] 인증번호 확인 함수
  void _verifyOtp() {
    String otp = _otpControllers.map((e) => e.text).join();

    // 4. [해결] EmailOTP 클래스에서 직접 검증
    if (EmailOTP.verifyOTP(otp: otp)) {
      _showSnackBar("인증에 성공했습니다.");
      setState(() => _currentStep = 3);
    } else {
      _showSnackBar("인증번호가 일치하지 않습니다.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(_currentStep == 3 ? "비밀번호 변경" : "비밀번호 찾기", style: _ptStyle(size: 20, weight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: _buildBodyByStep(),
            ),
          ),
          if (_isLoading) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFFD45858)))),
        ],
      ),
    );
  }

  Widget _buildBodyByStep() {
    if (_currentStep == 1) return _step1Input();
    if (_currentStep == 2) return _step2Verify();
    return _step3Change();
  }

  // --- [1단계] 이름/이메일 입력 화면 ---
  Widget _step1Input() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 44),
        Text("회원가입시 입력한 정보로\n비밀번호를 찾을 수 있습니다", style: _ptStyle(size: 16, weight: FontWeight.w400)),
        const SizedBox(height: 30),

        // 🔸 이름 필드 추가
        _buildLabel("이름"),
        _buildTextField(_nameController, "이름을 입력해주세요"),
        const SizedBox(height: 24),

        // 이메일 필드
        _buildLabel("이메일"),
        _buildTextField(_emailController, "이메일을 입력해주세요", icon: Icons.email_outlined),

        const Spacer(),
        _buildMainButton("인증 번호 발송", _sendOtp),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- [2단계/3단계는 이전과 동일] ---
  Widget _step2Verify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 44),
        Text("본인 인증 코드가 이메일로 전송되었습니다.", style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 32),
        Center(child: TextButton(onPressed: _sendOtp, child: Text("인증 번호 다시 보내기", style: _ptStyle(size: 14, weight: FontWeight.w600, color: Colors.black)))),
        const Spacer(),
        _buildMainButton("인증 완료", _verifyOtp),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _step3Change() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 44),
        Text("변경하실 비밀번호를 입력해주세요", style: _ptStyle(size: 16, weight: FontWeight.w400)),
        const SizedBox(height: 40),
        _buildLabel("비밀번호"),
        _buildTextField(_pwController, "새 비밀번호", isObscure: true, icon: Icons.lock_outline),
        const SizedBox(height: 24),
        _buildLabel("비밀번호 확인"),
        _buildTextField(_pwConfirmController, "비밀번호 확인", isObscure: true, icon: Icons.lock_outline),
        const Spacer(),
        _buildMainButton("변경 완료", () => Navigator.pop(context)),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- 공통 위젯 빌더 ---
  Widget _buildLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))));

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon, bool isObscure = false}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFC2C2C2))),
      child: TextField(
        controller: controller, obscureText: isObscure,
        style: _ptStyle(size: 14, weight: FontWeight.w400),
        decoration: InputDecoration(
          hintText: hint, prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF767676)) : null,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    bool hasValue = _otpControllers[index].text.isNotEmpty;
    return Container(
      width: 68, height: 68,
      decoration: BoxDecoration(
        color: hasValue ? const Color(0xFFD45858).withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasValue ? const Color(0xFFD45858) : const Color(0xFFC2C2C2)),
      ),
      child: TextField(
        controller: _otpControllers[index], focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
        style: _ptStyle(size: 24, weight: FontWeight.w500),
        decoration: const InputDecoration(counterText: "", border: InputBorder.none),
        onChanged: (v) {
          setState(() {});
          if (v.isNotEmpty && index < 3) _otpFocusNodes[index + 1].requestFocus();
        },
      ),
    );
  }

  Widget _buildMainButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD45858), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
      child: Text(text, style: _ptStyle(size: 18, weight: FontWeight.w600, color: Colors.white)),
    );
  }
}