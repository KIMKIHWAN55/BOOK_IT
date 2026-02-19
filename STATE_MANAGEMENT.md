📘 BookIt 상태 관리 가이드 (STATE_MANAGEMENT.md)
이 문서는 BookIt 프로젝트에서 Riverpod을 활용하여 상태를 관리하는 원칙과 네이밍 규칙, 그리고 비동기 데이터 처리 기준을 정의합니다.

1. 사용 기술 및 버전
   패키지: flutter_riverpod (코드 제너레이션 사용 시 riverpod_annotation, riverpod_generator 병행)

버전: Riverpod 2.x 이상 (최신 AsyncNotifier / Notifier API 기준)

핵심 목표:

UI 위젯에는 어떠한 비즈니스 로직도 두지 않는다.

Firebase와의 통신(비동기 작업) 시 발생하는 로딩, 성공, 에러 상태를 일관되게 처리한다.

2. AsyncNotifier 사용 원칙
   Firebase를 데이터 소스로 사용하는 BookIt의 특성상, 대부분의 상태는 비동기(Asynchronous)로 처리됩니다. 따라서 상태 관리의 기본(Default) 클래스로 AsyncNotifier를 사용합니다.

📌 원칙 1: 상태의 초기화 (build 메서드)
build() 메서드는 해당 화면이나 기능이 처음 시작될 때 초기 데이터를 불러오는 역할을 합니다.
이곳에서 Repository를 호출하여 초기 데이터를 가져오며, 이 과정에서 Riverpod은 자동으로 로딩 상태(AsyncLoading)를 UI에 전달합니다.

Dart
class BookDetailController extends AsyncNotifier<BookModel> {
@override
FutureOr<BookModel> build(String bookId) async {
// ref.watch를 통해 Repository 주입
final repository = ref.watch(bookRepositoryProvider);
// 초기 데이터 로드 (로딩 상태 자동 처리)
return await repository.getBookById(bookId);
}
}
📌 원칙 2: UI에서의 상태 소비 (AsyncValue.when)
AsyncNotifier가 제공하는 AsyncValue를 UI에서 소비할 때는 반드시 when 메서드를 사용하여 3가지 상태(data, loading, error)를 모두 처리해야 합니다. 이를 통해 사용자는 항상 현재 상태에 맞는 피드백(로딩 스피너, 에러 메시지 등)을 볼 수 있습니다.

Dart
final bookState = ref.watch(bookDetailControllerProvider(bookId));

return bookState.when(
data: (book) => BookDetailWidget(book: book),
loading: () => const Center(child: CircularProgressIndicator()),
error: (error, stack) => Center(child: Text('데이터를 불러오지 못했습니다: $error')),
);
📌 원칙 3: 상태의 변경 (Mutation) 및 Optimistic UI 적용
데이터를 추가, 수정, 삭제하는 작업은 Controller 내부의 메서드로 캡슐화합니다.
사용자 경험(UX)을 위해, 서버(Firebase) 응답을 기다리기 전 UI 상태를 먼저 변경하고, 실패 시 롤백하는 Optimistic UI(낙관적 업데이트) 패턴을 지향합니다.

Dart
Future<void> toggleLike() async {
// 1. 기존 상태 백업
final previousState = state.value;
if (previousState == null) return;

// 2. UI 상태 즉시 업데이트 (로딩 없이 즉각 반응)
state = AsyncData(previousState.copyWith(
isLiked: !previousState.isLiked,
likeCount: previousState.isLiked ? previousState.likeCount - 1 : previousState.likeCount + 1,
));

try {
// 3. Repository를 통해 실제 데이터 통신
await ref.read(bookRepositoryProvider).updateLikeStatus(
bookId: previousState.id,
isLiked: !previousState.isLiked,
);
} catch (e) {
// 4. 실패 시 상태 롤백 및 에러 전달
state = AsyncData(previousState);
state = AsyncError(e, StackTrace.current);
}
}
3. Provider 네이밍 규칙 (Naming Convention)
   Riverpod은 앱 내에 여러 개의 Provider가 전역적으로 선언되므로, 이름만 보고도 역할과 반환 타입을 예측할 수 있어야 합니다. 모든 Provider는 **소문자 카멜케이스(camelCase)**로 시작하며, 용도에 따라 접미사(Suffix)를 통일합니다.

① xxxControllerProvider (비즈니스 로직 및 상태 변경)
대상: Notifier, AsyncNotifier, StateNotifier (구버전)

설명: 화면의 상태를 들고 있으며, 상태를 변경하는 비즈니스 메서드(액션)를 포함하는 경우.

예시:

authControllerProvider

cartControllerProvider

bookDetailControllerProvider

② xxxRepositoryProvider (데이터 통신/주입)
대상: Repository 클래스 인스턴스

설명: 상태를 직접 관리하지 않고, 단순히 외부 서비스와의 통신 객체를 제공(Provider)할 때 사용.

예시:

bookRepositoryProvider

authRepositoryProvider

③ xxxProvider (읽기 전용 상태 / 단순 값)
대상: 변경되지 않는 단순 값, 또는 다른 Provider를 조합하여 파생된 값을 계산하는 일반 Provider나 FutureProvider.

설명: 뒤에 Controller나 Repository 같은 별도 역할을 명시할 필요가 없는 단순 읽기 전용 상태.

예시:

currentUserProvider (현재 로그인한 유저 모델만 단순히 반환할 때)

filteredBooksProvider (검색어와 책 목록을 조합하여 필터링된 결과만 반환할 때)

4. 🚫 상태 관리 안티 패턴 (절대 하지 말아야 할 것)
   build() 메서드(UI) 안에서 ref.read로 상태 읽기

화면이 렌더링될 때 상태를 읽으려면 반드시 ref.watch를 사용하세요. ref.read는 버튼 클릭 같은 콜백(이벤트) 내부에서만 사용해야 합니다.

Controller 밖에서 직접 상태 조작하기

UI 파일에서 state = newValue 형태로 직접 상태를 바꾸지 마세요. 모든 상태 변경은 Controller 내부에 메서드를 만들어 호출(ref.read(provider.notifier).method())해야 합니다.

Repository에 ref 넘기기

Repository는 순수하게 데이터만 다루어야 합니다. Repository 내부에서 ref를 사용해 다른 상태를 읽어오는 것은 계층 간 결합도를 높이므로 피해야 합니다. 필요한 값은 Controller에서 Repository 메서드의 파라미터로 넘겨주세요.