import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoading;

  AuthState({this.isLoading = false});

  AuthState copyWith({bool? isLoading}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

//  Notifier 정의(비즈니스 로직)
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(isLoading: false);
  }

  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  // 이메일 로그인
  Future<String?> login(String email, String password) async {
    // 이미 로딩 중이면 중복 실행(연타) 방지
    if (state.isLoading) return null;

    _setLoading(true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email, password);
      return null;

    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');

    } finally {
      _setLoading(false);
    }
  }

  // 구글 로그인
  Future<String?> loginWithGoogle() async {
    if (state.isLoading) return null;

    _setLoading(true);
    try {
      final authService = ref.read(authServiceProvider);
      final userCredential = await authService.signInWithGoogle();

      if (userCredential == null) return 'cancel';

      return null;

    } catch (e) {
      return '구글 로그인 중 오류가 발생했습니다.\n${e.toString().replaceAll('Exception: ', '')}';

    } finally {
      _setLoading(false);
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});