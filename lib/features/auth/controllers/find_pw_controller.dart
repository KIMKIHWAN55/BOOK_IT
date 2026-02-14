import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class FindPwController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }

  // [옵션 A 적용] 유저 확인 후 Firebase 비밀번호 재설정 메일 발송
  Future<String?> sendResetLink(String name, String email) async {
    if (name.isEmpty || email.isEmpty) return "이름과 이메일을 모두 입력해주세요.";

    _setLoading(true);
    try {
      // 1. DB에 해당 이름+이메일을 가진 유저가 있는지 사전 검사
      bool exists = await _authService.checkUserExists(name: name, email: email);
      if (!exists) return "입력하신 정보와 일치하는 회원이 없습니다.";

      // 2. Firebase 비밀번호 재설정 메일 발송
      await _authService.sendPasswordResetEmail(email);
      return null; // 성공
    } catch (e) {
      return "오류가 발생했습니다: $e";
    } finally {
      _setLoading(false);
    }
  }
}