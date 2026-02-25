import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final findPwControllerProvider = NotifierProvider<FindPwController, bool>(() {
  return FindPwController();
});

class FindPwController extends Notifier<bool> {

  @override
  bool build() => false;

  Future<String?> sendResetLink(String name, String email) async {
    if (name.isEmpty || email.isEmpty) return "이름과 이메일을 입력해주세요.";

    state = true;
    try {
      final authService = ref.read(authServiceProvider);

      //  유저 존재 여부 확인
      final exists = await authService.checkUserExists(name: name, email: email);
      if (!exists) return "일치하는 회원 정보가 없습니다.";

      //  비밀번호 재설정 이메일 발송
      await authService.sendPasswordResetEmail(email);
      return null; // 성공

    } catch (e) {
      return "오류가 발생했습니다: $e";
    } finally {
      state = false;
    }
  }
}