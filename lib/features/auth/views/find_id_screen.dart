import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FindIdScreen extends StatefulWidget {
  const FindIdScreen({super.key});

  @override
  State<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends State<FindIdScreen> {
  int _currentStep = 1; // 1: 입력, 2: 인증, 3: 결과

  // 컨트롤러 및 포커스 노드
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  String _foundId = "";
  String _userName = "";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    for (var controller in _otpControllers) {controller.dispose();}
    for (var node in _otpFocusNodes) {node.dispose();}
    super.dispose();
  }

  // 폰트 스타일 공통 적용 함수 (Figma 수치 반영)
  TextStyle _ptStyle({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.4,
  }) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * -0.025, // letter-spacing: -0.025em
    );
  }

  // 데이터베이스 검색 로직
  Future<void> _searchId() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: name)
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _userName = name;
          _foundId = snapshot.docs.first.get('email'); // 가입시 저장한 ID 필드명으로 수정 가능
          _currentStep = 2;
        });
      } else {
        _showSnackBar("일치하는 정보가 없습니다.");
      }
    } catch (e) {
      _showSnackBar("오류가 발생했습니다. 다시 시도해주세요.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: _buildBodyByStep(),
        ),
      ),
    );
  }

  // --- UI Components ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("아이디 찾기", style: _ptStyle(size: 20, weight: FontWeight.w600, color: Colors.black)),
      centerTitle: true,
    );
  }

  Widget _buildBodyByStep() {
    if (_currentStep == 1) return _step1Input();
    if (_currentStep == 2) return _step2Verify();
    return _step3Result();
  }

  // [1단계] 입력 화면
  Widget _step1Input() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 44),
        Text("회원가입시 입력한 정보로\n아이디를 찾을 수 있습니다",
            style: _ptStyle(size: 16, weight: FontWeight.w400, color: const Color(0xFF222222))),
        const SizedBox(height: 30),
        _buildLabel("이름"),
        _buildTextField(_nameController, "이름을 입력해주세요"),
        const SizedBox(height: 20),
        _buildLabel("이메일"),
        _buildTextField(_emailController, "이메일을 입력해주세요", icon: Icons.email_outlined),
        const Spacer(),
        _buildMainButton("인증 번호 발송", _searchId),
        const SizedBox(height: 24),
      ],
    );
  }

  // [2단계] 인증 화면
  Widget _step2Verify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 44),
        Text("본인 인증 코드가 귀하에게 전송되었습니다.\n전달 받은 코드를 입력하셔야 합니다.",
            style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676), height: 1.43)),
        const SizedBox(height: 12),
        Row(children: [
          Text(_emailController.text, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF222222))),
          Text(" 코드를 보냈습니다.", style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
        ]),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 32),
        Center(child: TextButton(onPressed: () {},
            child: Text("인증 번호 다시 보내기", style: _ptStyle(size: 14, weight: FontWeight.w600, color: const Color(0xFF222222))))),
        const Spacer(),
        _buildMainButton("인증 완료", () => setState(() => _currentStep = 3)),
        const SizedBox(height: 24),
      ],
    );
  }

  // [3단계] 결과 화면
  Widget _step3Result() {
    return Column(
      children: [
        const Spacer(flex: 2),
        Center(
          child: Container(
            width: 50, height: 38,
            decoration: const BoxDecoration(color: Color(0xFF34A853)),
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ),
        const SizedBox(height: 40),
        Text("$_userName님의 아이디는", style: _ptStyle(size: 24, weight: FontWeight.w500, color: const Color(0xFF222222))),
        const SizedBox(height: 4),
        RichText(text: TextSpan(style: _ptStyle(size: 24, weight: FontWeight.w500, color: const Color(0xFF222222)),
            children: [
              TextSpan(text: _foundId, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD45858))),
              const TextSpan(text: " 입니다."),
            ])),
        const Spacer(flex: 3),
        _buildMainButton("계속 로그인", () => Navigator.popUntil(context, (route) => route.isFirst)),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFC2C2C2))),
      child: TextField(
        controller: controller,
        style: _ptStyle(size: 14, weight: FontWeight.w400, color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF767676)),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF767676)) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 68, height: 68,
      decoration: BoxDecoration(
        color: _otpControllers[index].text.isNotEmpty ? const Color(0xFFD45858).withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _otpControllers[index].text.isNotEmpty ? const Color(0xFFD45858) : const Color(0xFFC2C2C2)),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: _ptStyle(size: 24, weight: FontWeight.w500, color: const Color(0xFF222222), height: 1.0),
        decoration: const InputDecoration(counterText: "", border: InputBorder.none),
        onChanged: (v) {
          setState(() {});
          if (v.isNotEmpty && index < 3) _otpFocusNodes[index+1].requestFocus();
        },
      ),
    );
  }

  Widget _buildMainButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD45858),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(text, style: _ptStyle(size: 18, weight: FontWeight.w600, color: Colors.white)),
    );
  }
}