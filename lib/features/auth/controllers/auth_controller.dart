import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// 🌟 1. 상태 클래스 정의 (데이터를 담는 그릇)
class AuthState {
  final bool isLoading;

  AuthState({this.isLoading = false});

  AuthState copyWith({bool? isLoading}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 🌟 2. Notifier 정의 (비즈니스 로직)
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(isLoading: false); // 초기 상태
  }

  // 🔹 로딩 시작/종료 헬퍼 함수
  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  // 1. 이메일 로그인
  Future<String?> login(String email, String password) async {
    // 이미 로딩 중이면 중복 실행(연타) 방지
    if (state.isLoading) return null;

    _setLoading(true); // 로딩 시작
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email, password);
      return null; // 성공 시 에러 메시지 없음

    } catch (e) {
      // 🌟 [핵심 수정] AuthService에서 만든 친절한 에러 메시지를 텍스트만 깔끔하게 뽑아서 전달!
      return e.toString().replaceAll('Exception: ', '');

    } finally {
      _setLoading(false); // 로딩 끝
    }
  }

  // 2. 구글 로그인
  Future<String?> loginWithGoogle() async {
    if (state.isLoading) return null;

    _setLoading(true);
    try {
      final authService = ref.read(authServiceProvider);
      final userCredential = await authService.signInWithGoogle();

      // 사용자가 로그인 창을 닫았을 때 처리
      if (userCredential == null) return 'cancel';

      return null; // 성공

    } catch (e) {
      // 🌟 [수정] 구글 로그인 에러도 깔끔하게 포맷팅
      return '구글 로그인 중 오류가 발생했습니다.\n${e.toString().replaceAll('Exception: ', '')}';

    } finally {
      _setLoading(false);
    }
  }
}

// 🌟 3. Provider 생성 (UI에서 접근할 수 있는 통로)
final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});