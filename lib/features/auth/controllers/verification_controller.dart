import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 로그인 처리를 위해 필요

enum VerificationStatus { idle, success, duplicated, autoLoginFailed, error }

class VerificationController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isResending = false;
  bool get isResending => _isResending;

  int _timeLeft = 120;
  int get timeLeft => _timeLeft;
  Timer? _timer;

  // 타이머 시작
  void startTimer() {
    _timer?.cancel();
    _timeLeft = 120;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  // 컨트롤러가 버려질 때 타이머 정리
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 코드 재전송
  Future<String?> resendCode(String email) async {
    _isResending = true;
    notifyListeners();

    try {
      await _authService.resendVerificationCode(email);
      startTimer(); // 성공 시 타이머 재시작
      return null; // 성공
    } catch (e) {
      return '코드 재전송에 실패했습니다: $e';
    } finally {
      _isResending = false;
      notifyListeners();
    }
  }

  // 코드 확인 및 최종 가입, 그리고 자동 로그인까지 한 번에 처리
  Future<VerificationStatus> verifyAndSignup({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String phone,
    required String code,
    Function(String)? onError,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. 클라우드 함수 호출 (가입)
      final statusCode = await _authService.verifyCodeAndFinalizeSignup(
        email: email, password: password, name: name, nickname: nickname, code: code,
      );

      if (statusCode == 409) return VerificationStatus.duplicated;

      // 2. 가입 성공 시 자동 로그인
      if (statusCode == 200) {
        final userCredential = await _authService.signInWithEmail(email, password);

        if (userCredential.user != null) {
          // 3. Firestore 정보 저장
          await _authService.saveUserToFirestore(
            uid: userCredential.user!.uid,
            email: email,
            name: name,
            nickname: nickname,
            phone: phone,
          );
          return VerificationStatus.success;
        }
      }
      return VerificationStatus.error;
    } catch (e) {
      onError?.call(e.toString());
      return VerificationStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}