import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 로딩 상태 변경 함수
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 1. 이메일 로그인
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email, password);
      return null; // 성공
    } catch (e) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    } finally {
      _setLoading(false);
    }
  }

  // 2. 구글 로그인
  Future<String?> loginWithGoogle() async {
    _setLoading(true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential == null) return 'cancel';
      return null;
    } catch (e) {
      return 'Google 로그인 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 3. 이메일 인증 코드 발송 요청 (회원가입 단계에서 사용)
  Future<String?> requestVerificationCode(String email) async {
    _setLoading(true);
    try {
      // 🌟 실제 통신 로직은 서비스에 있는 함수를 호출합니다.
      await _authService.sendEmailVerificationCode(email);
      return null;
    } catch (e) {
      return '인증 코드 발송 실패: $e';
    } finally {
      _setLoading(false);
    }
  }
}