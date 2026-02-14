import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 🌟 중복 확인 상태 관리
  bool isEmailVerified = false;
  bool isNicknameVerified = false;

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }

  // 텍스트가 바뀌면 인증 상태 초기화
  void resetEmailCheck() { isEmailVerified = false; notifyListeners(); }
  void resetNicknameCheck() { isNicknameVerified = false; notifyListeners(); }

  // 이메일 중복 확인
  Future<String?> checkEmailDuplicate(String email) async {
    if (email.isEmpty) return "이메일을 입력해주세요.";
    _setLoading(true);
    try {
      bool isDup = await _authService.isEmailDuplicate(email.trim());
      if (isDup) return "이미 사용 중인 이메일입니다.";
      isEmailVerified = true;
      return null; // 사용 가능
    } finally {
      _setLoading(false);
    }
  }

  // 닉네임 중복 확인
  Future<String?> checkNicknameDuplicate(String nickname) async {
    if (nickname.isEmpty) return "닉네임을 입력해주세요.";
    _setLoading(true);
    try {
      bool isDup = await _authService.isNicknameDuplicate(nickname.trim());
      if (isDup) return "이미 사용 중인 닉네임입니다.";
      isNicknameVerified = true;
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 본인 인증 요청 (휴대폰 번호 추가됨)
  Future<String?> requestVerification({
    required String email, required String password, required String passwordConfirm,
    required String name, required String nickname, required String phone, // 🌟 phone 추가
  }) async {
    if (!isEmailVerified) return "이메일 중복 확인을 진행해주세요.";
    if (!isNicknameVerified) return "닉네임 중복 확인을 진행해주세요.";
    if (password != passwordConfirm) return '비밀번호가 일치하지 않습니다.';
    if (phone.isEmpty) return '휴대폰 번호를 입력해주세요.';

    _setLoading(true);
    try {
      await _authService.sendEmailVerificationCode(email);
      return null;
    } catch (e) {
      return '인증 코드 발송 실패: $e';
    } finally {
      _setLoading(false);
    }
  }
}