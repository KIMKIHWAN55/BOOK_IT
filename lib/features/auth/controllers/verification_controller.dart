import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

enum VerificationStatus { idle, success, duplicated, autoLoginFailed, error }

class VerificationState {
  final int timeLeft;
  final bool isLoading;
  final bool isResending;

  VerificationState({
    this.timeLeft = 120,
    this.isLoading = false,
    this.isResending = false,
  });

  VerificationState copyWith({int? timeLeft, bool? isLoading, bool? isResending}) {
    return VerificationState(
      timeLeft: timeLeft ?? this.timeLeft,
      isLoading: isLoading ?? this.isLoading,
      isResending: isResending ?? this.isResending,
    );
  }
}

// 🌟 autoDispose를 빼고 가장 기본적이고 안전한 NotifierProvider 사용
final verificationControllerProvider = NotifierProvider<VerificationController, VerificationState>(() {
  return VerificationController();
});

// 🌟 기본 Notifier 상속
class VerificationController extends Notifier<VerificationState> {
  Timer? _timer;

  @override
  VerificationState build() {
    return VerificationState();
  }

  // 🌟 수동으로 타이머를 끄는 함수 추가 (화면이 닫힐 때 호출할 예정)
  void disposeTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void startTimer() {
    disposeTimer(); // 기존 타이머가 있으면 끄기
    state = state.copyWith(timeLeft: 120); // 다시 들어와도 2분으로 초기화됨!

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        disposeTimer();
      }
    });
  }

  Future<String?> resendCode(String email) async {
    state = state.copyWith(isResending: true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendVerificationCode(email);
      startTimer();
      return null;
    } catch (e) {
      return '인증 코드 재전송 실패: $e';
    } finally {
      state = state.copyWith(isResending: false);
    }
  }

  Future<VerificationStatus> verifyAndSignup({
    required String email, required String password,
    required String name, required String nickname,
    required String phone, required String code,
    Function(String)? onError,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final authService = ref.read(authServiceProvider);
      final statusCode = await authService.verifyCodeAndFinalizeSignup(
        email: email, password: password, name: name, nickname: nickname, code: code,
      );

      if (statusCode == 409) {
        state = state.copyWith(isLoading: false);
        return VerificationStatus.duplicated;
      }

      if (statusCode == 200) {
        final userCredential = await authService.signInWithEmail(email, password);
        if (userCredential.user != null) {
          await authService.saveUserToFirestore(
            uid: userCredential.user!.uid, email: email, name: name, nickname: nickname, phone: phone,
          );
          state = state.copyWith(isLoading: false);
          return VerificationStatus.success;
        }
      }
      state = state.copyWith(isLoading: false);
      return VerificationStatus.error;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (onError != null) onError(e.toString());
      return VerificationStatus.error;
    }
  }
}