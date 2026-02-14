import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// 🌟 1. 상태 클래스 정의 (데이터를 담는 그릇)
// 화면이 다시 그려져야 할 데이터(여기서는 로딩 상태)를 정의합니다.
class AuthState {
  final bool isLoading;

  AuthState({this.isLoading = false});

  // 상태 복사본을 만드는 헬퍼 함수 (불변성 유지)
  AuthState copyWith({bool? isLoading}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 🌟 2. Notifier 정의 (비즈니스 로직)
// 기존 ChangeNotifier 역할을 합니다.
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
    _setLoading(true); // 로딩 시작
    try {
      // 🌟 Provider를 통해 AuthService 가져오기 (의존성 주입)
      final authService = ref.read(authServiceProvider);

      await authService.signInWithEmail(email, password);
      return null; // 성공 시 에러 메시지 없음
    } catch (e) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    } finally {
      _setLoading(false); // 로딩 끝
    }
  }

  // 2. 구글 로그인
  Future<String?> loginWithGoogle() async {
    _setLoading(true);
    try {
      final authService = ref.read(authServiceProvider);

      final userCredential = await authService.signInWithGoogle();

      // 사용자가 로그인 창을 닫았을 때 처리
      if (userCredential == null) return 'cancel';

      return null; // 성공
    } catch (e) {
      return 'Google 로그인 실패: $e';
    } finally {
      _setLoading(false);
    }
  }
}

// 🌟 3. Provider 생성 (UI에서 접근할 수 있는 통로)
final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});