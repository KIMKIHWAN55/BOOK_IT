import 'package:flutter/material.dart';
import '../../profile/views/profile_setup_screen.dart';
import '../controllers/verification_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final String nickname;
  final String phone;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.nickname,
    required this.phone,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final VerificationController _controller = VerificationController();
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentCode = "";

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
    _controller.startTimer(); // 컨트롤러의 타이머 시작
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    _controller.dispose(); // 컨트롤러 자원(타이머) 해제
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    _currentCode = _controllers.map((c) => c.text).join();
    if (value.isNotEmpty && index < 3) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    setState(() {});
  }

  Future<void> _handleResend() async {
    final error = await _controller.resendCode(widget.email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '인증 코드를 재전송했습니다.')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    final status = await _controller.verifyAndSignup(
      email: widget.email,
      password: widget.password,
      name: widget.name,
      nickname: widget.nickname,
      phone: widget.phone,
      code: _currentCode,
      onError: (msg) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $msg')));
      },
    );

    if (!mounted) return;

    switch (status) {
      case VerificationStatus.success:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileSetupScreen()));
        break;
      case VerificationStatus.duplicated:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 가입된 이메일입니다. 로그인 화면으로 이동합니다.')));
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        });
        break;
      case VerificationStatus.autoLoginFailed:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가입 완료. 로그인해주세요.')));
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case VerificationStatus.error:
      case VerificationStatus.idle:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
        title: const Text('본인 인증', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 80),
                        const Text('복구 코드가 귀하에게 전송되었습니다.\n전달 받은 코드를 2분안에 입력하셔야 합니다.', style: TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.4)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Flexible(child: Text(widget.email, style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            const Text(' 코드를 보냈습니다.', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) => _buildCodeBox(index)),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: _controller.timeLeft > 0
                              ? Text('코드 입력까지 ${_controller.timeLeft}초 남았습니다.', style: const TextStyle(fontSize: 14, color: AppColors.textSub))
                              : _controller.isResending
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : TextButton(onPressed: _handleResend, child: const Text('인증 코드 재전송', style: TextStyle(color: AppColors.primary))),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  if (_controller.isLoading)
                    Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
                ],
              ),
            );
          }
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                return PrimaryButton(
                  text: '입력 완료',
                  onPressed: (_currentCode.length == 4) ? _handleSubmit : null,
                  isLoading: _controller.isLoading,
                );
              }
          ),
        ),
      ),
    );
  }

  // 4개의 네모난 코드 입력창 그리는 위젯
  Widget _buildCodeBox(int index) {
    bool hasFocus = _focusNodes[index].hasFocus;
    bool hasText = _controllers[index].text.isNotEmpty;
    Color borderColor = hasFocus || hasText ? AppColors.primary : AppColors.border;

    return SizedBox(
      width: 68, height: 68,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        onChanged: (value) => _onCodeChanged(value, index),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: hasText ? AppColors.primary.withOpacity(0.2) : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }
}