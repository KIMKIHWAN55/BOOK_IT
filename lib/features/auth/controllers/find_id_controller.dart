import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class FindIdController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  int _currentStep = 1; // 1: 입력, 3: 결과 (2단계 삭제)
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

  // 1단계 -> 3단계: DB에서 아이디 검색 후 바로 결과 표시
  Future<String?> requestSearchId(String name, String phone) async {
    if (name.isEmpty || phone.isEmpty) return "이름과 휴대폰 번호를 입력해주세요.";

    _setLoading(true);
    try {
      final resultId = await _authService.findUserId(name: name, phone: phone);
      if (resultId != null) {
        _foundId = resultId;
        _userName = name;
        _currentStep = 3; // 🌟 2단계를 건너뛰고 바로 3단계(결과)로 이동!
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

  // 다시 처음으로 되돌리기
  void reset() {
    _currentStep = 1;
    _foundId = "";
    _userName = "";
    notifyListeners();
  }
}