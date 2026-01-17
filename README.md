# 📚 BookIt (북잇)

**"나만의 서재를 채우고, 독서 습관을 만드는 기록 애플리케이션"**

BookIt은 사용자가 읽은 책을 쉽고 간편하게 기록하고, 자신만의 서재를 관리하며 독서 습관을 형성하도록 돕는 모바일 앱입니다. Flutter와 Firebase를 기반으로 개발되었습니다.

## ✨ 주요 기능 (Features)

* **👤 사용자 관리**
    * 이메일 회원가입 및 로그인
    * **Google 소셜 로그인** (Firebase Authentication 연동)
    * 아이디/비밀번호 찾기 및 프로필 관리 (`MyPageScreen`)
* **📖 도서 관리 (서재)**
    * 도서 검색 및 내 서재에 등록 (`LibraryScreen`)
    * 독서 상태 관리 (읽을 책, 읽고 있는 책, 읽은 책)
    * **관리자 모드**: 도서 데이터 추가/수정/삭제 (`AdminBookListScreen`)
* **✍️ 커뮤니티 & 기록**
    * 독서 감상문 및 게시글 작성 (`WritePostScreen`)
    * 사용자 간 독서 기록 공유 (`PostBoardScreen`)
* **🛒 기타 편의 기능**
    * 장바구니 기능 (`CartScreen`)
    * 직관적인 앱 소개 및 온보딩 화면 (`AppIntroScreen`)

## 🛠 기술 스택 (Tech Stack)

* **Frontend:** Flutter (Dart)
* **Backend (Serverless):** Firebase (Auth, Firestore, Storage)
* **State Management:** `setState` (직관적인 상태 관리 지향)

## 🏗️ 시스템 구조 및 설계 (Architecture & Design)

이 프로젝트는 유지보수와 확장성을 고려하여 **MVVM 패턴**을 지향하며, 데이터와 UI를 분리하여 설계되었습니다.

### 1. 폴더 구조 (Directory Structure)
```text
lib/
├── models/          # 데이터 모델 (Book, User 등 데이터 구조 정의)
├── screens/         # UI 화면 (로그인, 메인, 서재, 관리자 페이지 등)
├── firebase_options.dart  # Firebase 설정 파일
└── main.dart        # 앱 진입점 및 테마, 라우팅 설정

2. 데이터베이스 설계 (Firestore Schema)
Collection,Document ID,주요 필드 (Fields),설명
users,uid (Auth ID),"email, nickname, profileImage, createdAt",사용자 기본 정보
books,Auto ID,"title, author, description, imageUrl, uid",등록된 도서 정보
posts,Auto ID,"bookId, userId, content, rating, date",독서 감상문 및 게시글