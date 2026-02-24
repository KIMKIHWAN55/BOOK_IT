📚 BookIt (북잇)
"나만의 서재를 채우고, 독서 습관을 만드는 AI 기반 독서 커뮤니티 플랫폼"

BookIt은 사용자가 읽은 책을 간편하게 기록하고 자신만의 서재를 관리할 수 있도록 돕는 모바일 애플리케이션입니다. 단순한 기록을 넘어, 사용자 간의 독서 감상문 공유(커뮤니티)와 생성형 AI를 활용한 맞춤형 도서 추천 기능을 제공하여 독서의 즐거움을 극대화합니다.

🛠 기술 스택 (Tech Stack)
Frontend
Framework: Flutter (Dart)

State Management: Riverpod (Notifier, StreamProvider, AsyncNotifier)

Architecture: Feature-first Architecture (MVVM 기반 분리)

Backend (Serverless)
Database: Firebase Firestore

Authentication: Firebase Authentication (Email, Google)

Server/API: Firebase Cloud Functions (Node.js)

Storage: Firebase Cloud Storage

AI & 3rd Party
AI: OpenAI API (gpt-4o-mini)

✨주요 기능 (Features)
🤖 1. AI 사서 '부기' (RAG 기반 맞춤형 도서 추천)
상황별 맞춤 추천: 사용자가 현재 기분이나 상황을 채팅으로 입력하면, 앱 내에 등록된 도서 목록 중 가장 알맞은 책을 분석하여 추천합니다.

바로가기 연동: AI가 답변과 함께 특정 책의 ID를 반환하면, 클라이언트(Flutter)에서 이를 파싱하여 [책 보러가기] UI 버튼을 동적으로 생성합니다.

✍️ 2. 독서 커뮤니티 및 기록
독서 감상문 공유: 내가 읽은 책에 대한 평점과 감상문을 해시태그와 함께 작성하고 피드에 공유합니다.

소셜 기능: Riverpod의 AsyncNotifier를 활용하여 낙관적 업데이트(Optimistic UI)가 적용된 매끄러운 좋아요 및 댓글/대댓글 기능을 제공합니다.

📖 3. 도서 관리 (내 서재 & 관리자)
내 서재: 관심 있는 책, 읽고 있는 책, 다 읽은 책을 상태별로 나누어 관리합니다.

관리자 모드: 앱에서 제공할 도서 데이터를 추가, 수정, 삭제하고 프로모션 배너를 관리할 수 있습니다.

👤 4. 사용자 인증 및 편의 기능
인증: 이메일 및 Google 소셜 로그인 지원

장바구니/결제: 원하는 도서를 장바구니에 담고 모의 결제를 진행할 수 있는 플로우 제공

🏗️ 시스템 구조 및 설계 (Architecture)
유지보수와 확장성을 극대화하기 위해 기존 setState 기반의 모놀리식 구조에서 Feature-first (기능 단위) 아키텍처로 리팩토링했습니다. UI와 비즈니스 로직, 데이터 접근 계층을 철저히 분리했습니다.

📂 Directory Structure
Plaintext
lib/
├── core/            # 라우팅, 테마, 상수(Constants) 등 앱 전역 설정
├── features/        # 도메인(기능)별 독립된 모듈 구성
│   ├── auth/        # 인증 (회원가입, 로그인 등)
│   ├── board/       # 게시판 및 커뮤니티 피드
│   ├── book/        # 도서 검색 및 상세 페이지
│   ├── cart/        # 장바구니 및 결제
│   └── chat/        # AI 챗봇 기능
│       ├── models/         # 데이터 모델 (JSON 직렬화)
│       ├── views/          # 화면 UI (Screen, Widget)
│       ├── controllers/    # Riverpod 상태 관리 및 비즈니스 로직
│       └── repositories/   # Firestore API 통신 및 데이터 가공
├── shared/          # 공통 사용 위젯 (버튼, 앱바, 이미지 포맷터 등)
└── main.dart        # 앱 진입점

🗄️ Database Schema (Firestore)CollectionDocument ID주요 필드 (Fields)설명usersuid (Auth)nickname, profileImage, createdAt회원 정보booksAuto IDtitle, author, category, description등록된 도서 정보postsAuto IDuid, bookId, content, tags, likedBy사용자가 작성한 게시글/리뷰commentsAuto IDpostId, uid, content, parentId게시글의 댓글 (대댓글 지원)cartuid (Auth)items(Array of Book References)사용자별 장바구니