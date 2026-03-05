# Firestore 컬렉션 스키마

> BookIt 프로젝트의 Cloud Firestore 전체 컬렉션 구조와 각 문서의 필드를 정의합니다.

---

## 최상위 컬렉션 구조

```
Firestore Root
├── users/          # 사용자 계정 정보
├── books/          # 도서 정보
└── posts/          # 커뮤니티 게시글
```

---

## 1. `users` 컬렉션

**경로:** `/users/{uid}`
**문서 ID:** Firebase Auth UID

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|:----:|------|
| `email` | String | O | 이메일 주소 |
| `name` | String | O | 실명 |
| `nickname` | String | O | 닉네임 (앱 내 표시명, 중복 불가) |
| `role` | String | O | 권한 — `"user"` \| `"admin"` |
| `phone` | String | △ | 전화번호 (이메일 가입자만 존재) |
| `bio` | String | X | 자기소개 |
| `profileImage` | String | X | Storage 업로드 프로필 이미지 URL |
| `photoUrl` | String | X | Google 계정 프로필 사진 URL |
| `isProfileSetupComplete` | Boolean | X | 최초 프로필 설정 완료 여부 |
| `createdAt` | Timestamp | O | 계정 생성 시각 (서버 타임스탬프) |

> `profileImage` vs `photoUrl`: `profileImage`는 Storage에 직접 업로드한 사진,
> `photoUrl`은 Google 로그인 시 구글 계정 사진입니다. 각각 별도 필드로 관리됩니다.

### 문서 예시

```json
{
  "email": "user@example.com",
  "name": "홍길동",
  "nickname": "책벌레123",
  "role": "user",
  "phone": "010-1234-5678",
  "bio": "책을 좋아합니다",
  "profileImage": "https://firebasestorage.googleapis.com/...",
  "isProfileSetupComplete": true,
  "createdAt": "Timestamp"
}
```

---

### 1.1 서브컬렉션: `cart`

**경로:** `/users/{uid}/cart/{bookId}`
**문서 ID:** `bookId` (동일 도서 중복 담기 방지)

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `id` | String | 도서 ID |
| `title` | String | 도서 제목 |
| `author` | String | 저자 |
| `imageUrl` | String | 표지 이미지 URL |
| `originalPrice` | Number | 정가 (원) |
| `discountedPrice` | Number | 할인 적용가 (원) |
| `addedAt` | Timestamp | 장바구니 담은 시각 |

---

### 1.2 서브컬렉션: `purchased_books`

**경로:** `/users/{uid}/purchased_books/{bookId}`
**문서 ID:** `bookId`

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `id` | String | 도서 ID |
| `title` | String | 도서 제목 |
| `author` | String | 저자 |
| `imageUrl` | String | 표지 이미지 URL |
| `price` | Number | 구매 당시 결제 금액 (원) |
| `currentPage` | Number | 현재 읽은 페이지 (독서 기록) |
| `purchasedAt` | Timestamp | 구매 시각 |

---

### 1.3 서브컬렉션: `liked_books`

**경로:** `/users/{uid}/liked_books/{bookId}`
**문서 ID:** `bookId`

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `title` | String | 도서 제목 |
| `author` | String | 저자 |
| `imageUrl` | String | 표지 이미지 URL |
| `likedAt` | Timestamp | 좋아요 누른 시각 |

---

### 1.4 서브컬렉션: `liked_feeds`

**경로:** `/users/{uid}/liked_feeds/{postId}`
**문서 ID:** `postId`

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `content` | String | 게시글 내용 (요약) |
| `bookTitle` | String | 연관 도서 제목 |
| `bookImageUrl` | String | 연관 도서 표지 이미지 URL |
| `likedAt` | Timestamp | 좋아요 누른 시각 |

---

## 2. `books` 컬렉션

**경로:** `/books/{bookId}`
**문서 ID:** Firestore 자동 생성 ID

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|:----:|------|
| `rank` | Number | O | 순위 |
| `title` | String | O | 도서 제목 |
| `author` | String | O | 저자 |
| `imageUrl` | String | O | 표지 이미지 URL |
| `category` | String | O | 대분류 카테고리 (예: `"소설"`) |
| `tags` | Array\<String\> | O | 세부 태그 (예: `["#소설", "#SF"]`) |
| `description` | String | O | 줄거리/소개 |
| `price` | Number | O | 정가 (원) |
| `discountRate` | Number | X | 할인율 (%) — 없으면 필드 자체가 없음 |
| `rating` | String | O | 평균 평점 (소수점 1자리 문자열, 예: `"4.5"`) |
| `reviewCount` | String | O | 리뷰 총 개수 (문자열, 예: `"15"`) |

> `rating`, `reviewCount`를 String으로 저장하는 이유: 초기 데이터 입력 시 문자열로 등록된 레거시 데이터와의
> 호환성 때문입니다. `BookModel.fromFirestore`에서 `double.tryParse` / `int.tryParse`로 안전하게 변환합니다.

### 문서 예시

```json
{
  "rank": 1,
  "title": "채식주의자",
  "author": "한강",
  "imageUrl": "https://...",
  "category": "소설",
  "tags": ["#소설", "#한국문학", "#부커상"],
  "description": "세 편의 연작으로 구성된...",
  "price": 13000,
  "discountRate": 10,
  "rating": "4.8",
  "reviewCount": "42"
}
```

---

### 2.1 서브컬렉션: `reviews`

**경로:** `/books/{bookId}/reviews/{reviewId}`
**문서 ID:** Firestore 자동 생성 ID

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `uid` | String | 작성자 UID |
| `userName` | String | 작성자 닉네임 |
| `content` | String | 리뷰 내용 |
| `rating` | Number | 별점 (1.0 ~ 5.0) |
| `createdAt` | Timestamp | 작성 시각 |

---

## 3. `posts` 컬렉션

**경로:** `/posts/{postId}`
**문서 ID:** Firestore 자동 생성 ID

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|:----:|------|
| `uid` | String | O | 작성자 UID |
| `nickname` | String | O | 작성자 닉네임 (비정규화 저장) |
| `content` | String | O | 게시글 본문 |
| `tags` | Array\<String\> | O | 태그 목록 |
| `bookId` | String | X | 연관 도서 ID |
| `bookTitle` | String | X | 연관 도서 제목 (비정규화) |
| `bookAuthor` | String | X | 연관 도서 저자 (비정규화) |
| `bookImageUrl` | String | X | 연관 도서 표지 이미지 URL (비정규화) |
| `bookRating` | Number | X | 작성자가 매긴 도서 평점 |
| `bookReviewCount` | Number | X | 작성 시점 도서 리뷰 수 |
| `likeCount` | Number | O | 좋아요 수 (카운터 필드) |
| `commentCount` | Number | O | 댓글 수 (카운터 필드) |
| `likedBy` | Array\<String\> | O | 좋아요 누른 유저 UID 배열 |
| `createdAt` | Timestamp | O | 작성 시각 |
| `updatedAt` | Timestamp | X | 마지막 수정 시각 |

> **비정규화 전략:** `bookTitle`, `bookAuthor` 등 도서 정보를 게시글 문서에 직접 저장하여
> 목록 조회 시 `books` 컬렉션 추가 참조 없이 한 번의 쿼리로 렌더링합니다.

---

### 3.1 서브컬렉션: `comments`

**경로:** `/posts/{postId}/comments/{commentId}`
**문서 ID:** Firestore 자동 생성 ID

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `uid` | String | 작성자 UID |
| `nickname` | String | 작성자 닉네임 |
| `content` | String | 댓글 내용 |
| `parentId` | String \| null | 부모 댓글 ID (대댓글이면 부모 ID, 최상위면 `null`) |
| `isDeleted` | Boolean | 소프트 삭제 여부 |
| `createdAt` | Timestamp | 작성 시각 |

> **소프트 삭제:** 댓글 삭제 시 문서를 완전히 삭제하지 않고 `content`를 `"삭제된 댓글입니다."`로 교체하고
> `isDeleted: true`로 마킹합니다. 대댓글이 연결된 부모 댓글의 구조를 유지하기 위한 설계입니다.
