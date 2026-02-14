import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class FindIdController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  int _currentStep = 1; // 1: 입력, 2: 인증, 3: 결과
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _foundId = "";
  String get foundId => _foundId;

  String _userName = "";
  String get userName => _userName;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 1단계 -> 2단계: DB에서 아이디 검색 및 인증번호 발송 처리
  Future<String?> requestSearchId(String name, String phone) async {
    if (name.isEmpty || phone.isEmpty) return "폰번호를 입력해주세요.";

    _setLoading(true);
    try {
      final resultId = await _authService.findUserId(name: name, phone: phone);
      if (resultId != null) {
        _foundId = resultId;
        _userName = name;
        _currentStep = 2; // 찾았으면 2단계(인증)로 이동
        return null; // 성공
      } else {
        return "일치하는 정보가 없습니다.";
      }
    } catch (e) {
      return "오류가 발생했습니다: $e";
    } finally {
      _setLoading(false);
    }
  }

  // 2단계 -> 3단계: 인증번호 확인 로직 (현재는 UI 흐름상 바로 3단계로 넘김)
  void verifyOtp(String code) {
    // TODO: 실제 인증번호 검증 로직 추가 필요
    _currentStep = 3;
    notifyListeners();
  }

  // 다시 처음으로 되돌리기
  void reset() {
    _currentStep = 1;
    _foundId = "";
    _userName = "";
    notifyListeners();
  }
}