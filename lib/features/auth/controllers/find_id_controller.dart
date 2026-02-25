import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class FindIdState {
  final int currentStep;
  final bool isLoading;
  final String foundId;
  final String userName;

  FindIdState({
    this.currentStep = 1,
    this.isLoading = false,
    this.foundId = "",
    this.userName = "",
  });

  FindIdState copyWith({int? currentStep, bool? isLoading, String? foundId, String? userName}) {
    return FindIdState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      foundId: foundId ?? this.foundId,
      userName: userName ?? this.userName,
    );
  }
}

final findIdControllerProvider = NotifierProvider<FindIdController, FindIdState>(() {
  return FindIdController();
});

class FindIdController extends Notifier<FindIdState> {
  @override
  FindIdState build() => FindIdState();

  Future<String?> requestSearchId(String name, String phone) async {
    if (name.isEmpty || phone.isEmpty) return "이름과 휴대폰 번호를 입력해주세요.";

    state = state.copyWith(isLoading: true);
    try {
      final authService = ref.read(authServiceProvider);
      final resultId = await authService.findUserId(name: name, phone: phone);

      if (resultId != null) {
        state = state.copyWith(
          foundId: resultId,
          userName: name,
          currentStep: 3,
          isLoading: false,
        );
        return null;
      } else {
        state = state.copyWith(isLoading: false);
        return "일치하는 정보가 없습니다.";
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return "오류가 발생했습니다: $e";
    }
  }

  void reset() {
    state = FindIdState();
  }
}