🏗️ BookIt 아키텍처 및 설계 가이드 (ARCHITECTURE.md)
본 문서는 BookIt 프로젝트의 전반적인 시스템 구조, 의존성 규칙, 상태 관리 정책 및 테스트 전략을 정의합니다. 프로젝트에 참여하는 모든 개발자는 코드를 작성하기 전 이 문서를 반드시 숙지해야 합니다.

1. 계층 구조 및 폴더 설계 (Layered Architecture & Directory Structure)
   BookIt은 유지보수성과 확장성을 위해 도메인(Feature) 단위로 폴더를 분리하고, 각 도메인 내부는 철저하게 역할에 따라 계층을 나눕니다.

Plaintext
lib/
├── core/                # 앱 전반을 관통하는 핵심 설정 (라우팅, 테마, 글로벌 상수)
│   ├── constants/       # app_colors.dart 등
│   └── router/          # app_router.dart
├── shared/              # 도메인에 종속되지 않는 공통 재사용 컴포넌트
│   └── widgets/         # custom_text_field.dart, primary_button.dart 등
└── features/            # 도메인(기능) 단위 모듈 분리
├── auth/            # 인증 관련 기능
├── book/            # 도서 관련 기능
│   ├── models/        # [Data] 데이터 구조 정의 (book_model.dart)
│   ├── repositories/  # [Data] 외부 데이터 통신 전담 (book_repository.dart)
│   ├── controllers/   # [Domain] 비즈니스 로직 및 상태 관리 (book_detail_controller.dart)
│   └── views/         # [Presentation] 사용자 화면 및 UI (book_detail_screen.dart)
└── profile/         # 사용자 프로필 기능
2. 의존성 규칙 (Dependency Rule)
   본 프로젝트는 단방향 데이터 흐름을 철저히 준수합니다. 각 계층은 자신보다 안쪽에 있는(데이터와 가까운) 계층만 참조할 수 있으며, 역방향 참조는 엄격히 금지됩니다.

Plaintext
Presentation Layer (View)
↓
Domain Layer (Controller)
↓
Data Layer (Repository)
↓
External Data Source (Firebase)
🚫 건너뛰기 금지: View에서 곧바로 Repository를 호출하거나, FirebaseFirestore.instance에 직접 접근할 수 없습니다.

🔥 절대 규칙: 모든 데이터 변경과 비즈니스 로직 처리는 반드시 Controller를 통해서만 이루어집니다.

3. 핵심 설계 원칙: 왜 이렇게 설계했는가?
   Repository 패턴 도입

설계 이유: 데이터의 출처(Data Source)를 비즈니스 로직(Controller)으로부터 완벽하게 분리하기 위함입니다.

기대 효과: 현재는 Firebase를 사용 중이지만, 추후 데이터베이스를 Supabase나 Local DB로 마이그레이션해야 할 때 View나 Controller의 코드는 단 한 줄도 수정할 필요가 없습니다. 오직 Repository 계층의 내부 구현만 교체하면 됩니다.

Controller 계층 구축

설계 이유: UI 위젯이 복잡한 상태 처리(로딩, 에러, 성공) 로직을 직접 가지지 않도록 책임을 분리합니다. UI는 오직 '상태를 보여주는 역할'만 수행합니다.

4. Async 상태 처리 정책 (State Management)
   상태 관리는 Riverpod을 사용하며, 비동기 처리가 주를 이루는 프로젝트 특성상 다음 정책을 따릅니다.

모든 비동기 로직은 AsyncNotifier 내부에서 관리한다.

build()는 초기 데이터 로딩만 담당한다. (화면 진입 시 최초 1회 실행)

사용자 액션(예: toggleLike, addToCart)은 별도의 메서드로 분리하여 구현한다.

로딩 / 에러 / 성공 상태는 Riverpod의 AsyncValue 객체 하나로 일관되게 처리한다. (UI에서는 when을 통해 각 상태에 맞는 화면을 렌더링)

5. 상태 흐름 (Data Flow) 예시
   UI에서 이벤트가 발생했을 때 데이터가 어떻게 흘러가는지 보여주는 표준 플로우입니다.

📌 예제: 도서 '좋아요(Like)' 기능 동작 흐름
Plaintext
[1. View]
사용자가 하트(좋아요) 버튼을 클릭합니다.
➔ ref.read(bookDetailControllerProvider.notifier).toggleLike(bookId); 호출

[2. Controller]
1) UI 반응성을 위해 상태를 즉시 업데이트합니다 (Optimistic UI - 옵션).
2) 실제 데이터 변경을 위해 Repository를 호출합니다.
   ➔ await ref.read(bookRepositoryProvider).updateLikeStatus(bookId);

[3. Repository]
외부 서비스(Firebase Firestore)와 직접 통신합니다.
➔ FirebaseFirestore.instance.collection('books').doc(bookId).update(...);
➔ 성공/실패 여부를 Controller로 반환(또는 Exception Throw)합니다.

[4. View Update]
Controller에서 결과에 따라 상태(AsyncValue)를 갱신하면,
해당 Provider를 `ref.watch`하고 있던 View가 자동으로 Re-build 되어 최신 상태를 표시합니다.
6. Provider 네이밍 규칙 (Naming Convention)
   Provider 지옥을 방지하고 코드 가독성을 높이기 위해 아래의 규칙을 강제합니다.

xxxProvider (읽기 전용 상태): 단순히 값을 제공하거나 파생된 상태를 읽을 때.

xxxControllerProvider (상태 변경 담당): 상태를 변경하는 비즈니스 메서드(액션)를 포함하는 AsyncNotifier 계열.

xxxRepositoryProvider (데이터 계층): Repository 인스턴스를 의존성 주입(DI)하기 위해 사용.

7. 테스트 전략 (Testing Strategy)
   BookIt은 안정성 확보를 위해 아키텍처 단계부터 테스트 용이성(Testability)을 고려하여 설계되었습니다.

Controller 계층 테스트: UI 컴포넌트(위젯)와 완벽히 분리되어 있으므로, 렌더링 환경 없이 비즈니스 로직(Controller)만 독립적으로 단위 테스트(Unit Test)가 가능해야 합니다.

의존성 주입(DI)과 Mocking: Repository는 Provider를 통해 의존성이 주입됩니다. 따라서 테스트 환경에서는 실제 네트워크를 타는 Firebase Repository 대신, 가짜 데이터를 반환하는 MockRepository를 손쉽게 갈아 끼울 수 있습니다.

외부 의존성 격리: Firebase 직접 호출 코드는 오직 Repository 내부에만 존재하므로, 테스트 코드 작성 시 부작용(Side Effect)을 완벽히 통제할 수 있습니다.