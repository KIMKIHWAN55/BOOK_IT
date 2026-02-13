import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookit_app/features/profile/views/profile_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final String nickname;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.nickname,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentCode = "";
  bool _isLoading = false;
  bool _isResending = false;

  Timer? _timer;
  int _start = 120;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (!mounted) return;
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  // ★★★★★ URL 주소를 올바르게 수정한 함수 ★★★★★
  Future<void> _resendCode() async {
    setState(() { _isResending = true; });
    try {
      final url = Uri.parse('https://sendverificationcode-o4apuahgma-uc.a.run.app');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          // ✨ 공백제거 + 소문자화
          'email': widget.email.trim().toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증 코드를 재전송했습니다.')),
          );
          setState(() { _start = 120; });
          startTimer();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('코드 재전송에 실패했습니다: ${response.body}')),
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
      if (mounted) setState(() { _isResending = false; });
    }
  }


  Future<void> _verifyCodeAndSignUp() async {
    setState(() { _isLoading = true; });

    try {
      // 1. 클라우드 함수에 인증 및 가입 요청
      final url = Uri.parse('https://verifycodeandfinalizesignup-o4apuahgma-uc.a.run.app');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email.trim().toLowerCase(),
          'password': widget.password,
          'name': widget.name,
          'nickname': widget.nickname,
          'code': _currentCode,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // 2. 가입 성공 시, 바로 "자동 로그인"을 수행해 userCredential을 얻습니다.
          try {
            final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: widget.email,
              password: widget.password,
            );

            // ---------------------------------------------------------
            // 🌟 [여기입니다] 질문하신 코드를 이 위치에 넣습니다.
            // ---------------------------------------------------------
            if (userCredential.user != null) {
              // Firestore에 기본 정보 저장
              await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                'email': widget.email, // widget.email로 변수명 맞춰주세요
                'role': 'user',
                'name': widget.name,      // 가입 시 입력받은 이름
                'nickname': widget.nickname, // 가입 시 입력받은 닉네임
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              // 바로 로그인화면/메인으로 가지 않고 프로필 설정 화면으로 이동
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                );
              }
            }
            // ---------------------------------------------------------

          } catch (e) {
            // 자동 로그인 실패 시 (네트워크 오류 등) -> 로그인 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('가입은 완료되었으나 자동 로그인에 실패했습니다. 로그인해주세요.')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } else if (response.statusCode == 409) {
        // 이미 가입된 이메일 처리
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 가입된 이메일입니다. 로그인 화면으로 이동합니다.')),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        // 기타 인증 실패
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('인증에 실패했습니다: ${response.body}')),
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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    _currentCode = _controllers.map((c) => c.text).join();
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
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
        title: const Text('본인 인증',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    '복구 코드가 귀하에게 전송되었습니다.\n전달 받은 코드를 2분안에 입력하셔야 합니다.',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF767676), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Flexible(
                        child: Text(widget.email,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(' 코드를 보냈습니다.',
                          style:
                          TextStyle(fontSize: 14, color: Color(0xFF767676))),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) => _buildCodeBox(index)),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _start > 0
                        ? Text('코드 입력까지 $_start초 남았습니다.',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF767676)))
                        : _isResending
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2,))
                        : TextButton(
                        onPressed: _resendCode,
                        child: const Text('인증 코드 재전송')),
                  ),
                  const Spacer(),
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
            onPressed: (_currentCode.length == 4 && !_isLoading)
                ? _verifyCodeAndSignUp
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD45858),
              disabledBackgroundColor: const Color(0xFFD45858).withOpacity(0.5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('입력 완료',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBox(int index) {
    bool hasFocus = _focusNodes[index].hasFocus;
    bool hasText = _controllers[index].text.isNotEmpty;

    return SizedBox(
      width: 68,
      height: 68,
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
          fillColor:
          hasText ? const Color.fromRGBO(212, 88, 88, 0.2) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: hasFocus || hasText
                    ? const Color(0xFFD45858)
                    : const Color(0xFFC2C2C2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: hasFocus || hasText
                    ? const Color(0xFFD45858)
                    : const Color(0xFFC2C2C2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD45858), width: 1.5),
          ),
        ),
      ),
    );
  }
}

