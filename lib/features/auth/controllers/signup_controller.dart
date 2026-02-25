import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class SignupState {
  final bool isLoading;
  final bool isEmailVerified;
  final bool isNicknameVerified;

  SignupState({
    this.isLoading = false,
    this.isEmailVerified = false,
    this.isNicknameVerified = false,
  });

  // 상태 업데이트용 copyWith 메서드
  SignupState copyWith({bool? isLoading, bool? isEmailVerified, bool? isNicknameVerified}) {
    return SignupState(
      isLoading: isLoading ?? this.isLoading,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isNicknameVerified: isNicknameVerified ?? this.isNicknameVerified,
    );
  }
}

final signupControllerProvider = NotifierProvider<SignupController, SignupState>(() {
  return SignupController();
});

class SignupController extends Notifier<SignupState> {

  @override
  SignupState build() => SignupState();

  // 텍스트 변경 시 인증 초기화
  void resetEmailCheck() => state = state.copyWith(isEmailVerified: false);
  void resetNicknameCheck() => state = state.copyWith(isNicknameVerified: false);

  Future<String?> checkEmailDuplicate(String email) async {
    if (email.isEmpty) return "이메일을 입력해주세요.";
    state = state.copyWith(isLoading: true);
    try {
      final authService = ref.read(authServiceProvider);
      bool isDup = await authService.isEmailDuplicate(email.trim());
      if (isDup) return "이미 사용 중인 이메일입니다.";

      state = state.copyWith(isEmailVerified: true);
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String?> checkNicknameDuplicate(String nickname) async {
    if (nickname.isEmpty) return "닉네임을 입력해주세요.";
    state = state.copyWith(isLoading: true);
    try {
      final authService = ref.read(authServiceProvider);
      bool isDup = await authService.isNicknameDuplicate(nickname.trim());
      if (isDup) return "이미 사용 중인 닉네임입니다.";

      state = state.copyWith(isNicknameVerified: true);
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // 본인 인증 발송
  Future<String?> requestVerification({
    required String email, required String password, required String passwordConfirm,
    required String name, required String nickname, required String phone,
  }) async {
    if (!state.isEmailVerified) return "이메일 중복 확인을 진행해주세요.";
    if (!state.isNicknameVerified) return "닉네임 중복 확인을 진행해주세요.";
    if (password != passwordConfirm) return '비밀번호가 일치하지 않습니다.';
    if (phone.isEmpty) return '휴대폰 번호를 입력해주세요.';

    state = state.copyWith(isLoading: true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendEmailVerificationCode(email);
      return null;
    } catch (e) {
      return '인증 코드 발송 실패: $e';
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}