# Firebase 보안 규칙

> BookIt 프로젝트의 Firestore 및 Firebase Storage 보안 규칙을 정의합니다.
> 이 파일의 내용을 Firebase Console > Rules 탭에 직접 적용합니다.

---

## 1. Firestore 보안 규칙

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ────────────────────────────────────────────
    // 공통 헬퍼 함수
    // ────────────────────────────────────────────

    // 로그인 여부 확인
    function isLoggedIn() {
      return request.auth != null;
    }

    // 문서의 특정 uid 필드와 현재 로그인 유저가 일치하는지 확인
    function isOwner(uid) {
      return isLoggedIn() && request.auth.uid == uid;
    }

    // 관리자 여부 확인 (users/{uid}.role == 'admin')
    function isAdmin() {
      return isLoggedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // ────────────────────────────────────────────
    // users 컬렉션
    // ────────────────────────────────────────────
    match /users/{uid} {
      // 본인 또는 관리자만 읽기 가능
      allow read: if isOwner(uid) || isAdmin();

      // 본인만 문서 생성 가능
      allow create: if isOwner(uid);

      // 본인만 수정 가능, 단 role과 createdAt은 클라이언트에서 변경 불가
      allow update: if isOwner(uid)
        && !request.resource.data.diff(resource.data)
              .affectedKeys().hasAny(['role', 'createdAt']);

      // 본인 또는 관리자만 삭제 가능 (탈퇴 처리)
      allow delete: if isOwner(uid) || isAdmin();

      // 장바구니: 본인만
      match /cart/{bookId} {
        allow read, write: if isOwner(uid);
      }

      // 구매한 책: 본인만
      match /purchased_books/{bookId} {
        allow read, write: if isOwner(uid);
      }

      // 좋아요한 책: 본인만
      match /liked_books/{bookId} {
        allow read, write: if isOwner(uid);
      }

      // 좋아요한 피드: 본인만
      match /liked_feeds/{postId} {
        allow read, write: if isOwner(uid);
      }
    }

    // ────────────────────────────────────────────
    // books 컬렉션
    // ────────────────────────────────────────────
    match /books/{bookId} {
      // 도서 읽기: 비로그인 포함 모든 사용자 허용
      allow read: if true;

      // 도서 등록/수정/삭제: 관리자만 가능
      allow create, update, delete: if isAdmin();

      // 리뷰 서브컬렉션
      match /reviews/{reviewId} {
        // 읽기: 모두 허용
        allow read: if true;

        // 작성: 로그인한 사용자만
        allow create: if isLoggedIn()
          && request.resource.data.uid == request.auth.uid;

        // 수정/삭제: 본인 리뷰만
        allow update, delete: if isOwner(resource.data.uid);
      }
    }

    // ────────────────────────────────────────────
    // posts 컬렉션
    // ────────────────────────────────────────────
    match /posts/{postId} {
      // 읽기: 모두 허용 (피드 공개)
      allow read: if true;

      // 작성: 로그인 + 자신의 uid로만 작성 가능
      allow create: if isLoggedIn()
        && request.resource.data.uid == request.auth.uid;

      // 수정 규칙
      allow update: if isLoggedIn() && (
        // 1. 본인 게시글 수정
        isOwner(resource.data.uid) ||
        // 2. 관리자
        isAdmin() ||
        // 3. 좋아요/댓글 카운터만 업데이트 (다른 유저도 가능)
        request.resource.data.diff(resource.data)
          .affectedKeys()
          .hasOnly(['likeCount', 'likedBy', 'commentCount'])
      );

      // 삭제: 본인 또는 관리자
      allow delete: if isOwner(resource.data.uid) || isAdmin();

      // 댓글 서브컬렉션
      match /comments/{commentId} {
        // 읽기: 모두 허용
        allow read: if true;

        // 작성: 로그인 + 자신의 uid로만
        allow create: if isLoggedIn()
          && request.resource.data.uid == request.auth.uid;

        // 수정/삭제: 본인 또는 관리자
        // 소프트 삭제(isDeleted: true) 포함
        allow update, delete: if isOwner(resource.data.uid) || isAdmin();
      }
    }
  }
}
```

---

## 2. Firebase Storage 보안 규칙

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // 프로필 이미지
    match /user_profile/{uid}.jpg {
      // 읽기: 모두 허용 (프로필 사진 공개)
      allow read: if true;

      // 쓰기: 본인만, 10MB 이하, 이미지 파일만
      allow write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // 그 외 경로는 모두 차단
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 3. 권한 매트릭스 요약

### Firestore

| 리소스 | 비로그인 | 일반 유저 (본인) | 일반 유저 (타인) | 관리자 |
|--------|:--------:|:----------------:|:----------------:|:------:|
| users 읽기 | X | O | X | O |
| users 수정 | X | O (role 제외) | X | O |
| users 삭제 | X | O | X | O |
| books 읽기 | O | O | O | O |
| books 수정/삭제 | X | X | X | O |
| reviews 읽기 | O | O | O | O |
| reviews 작성 | X | O | O | O |
| reviews 수정/삭제 | X | O (본인만) | X | O |
| posts 읽기 | O | O | O | O |
| posts 작성 | X | O | X | O |
| posts 수정 | X | O (본인) | 카운터만 | O |
| posts 삭제 | X | O (본인) | X | O |
| comments 읽기 | O | O | O | O |
| comments 작성 | X | O | O | O |
| comments 수정/삭제 | X | O (본인) | X | O |
| 서브컬렉션 (cart 등) | X | O | X | X |

### Storage

| 경로 | 읽기 | 쓰기 |
|------|:----:|:----:|
| `user_profile/{uid}.jpg` | 모두 | 본인만 (10MB 이하, 이미지) |
| 그 외 | X | X |

---

## 4. 주요 보안 설계 결정

### role 필드 보호
클라이언트가 직접 `role` 필드를 `"admin"`으로 바꾸는 것을 막기 위해
`update` 규칙에서 `affectedKeys().hasAny(['role', 'createdAt'])` 변경 시 거부합니다.
`role` 변경은 Firebase Console 또는 Admin SDK를 통해서만 가능합니다.

### 게시글 좋아요 카운터 허용
`likeCount`, `likedBy`, `commentCount`는 게시글 작성자가 아닌 다른 유저도 업데이트해야 합니다.
`hasOnly(['likeCount', 'likedBy', 'commentCount'])` 조건으로 해당 필드만 변경을 허용하고
나머지 필드(content, title 등)는 타인이 수정하지 못하도록 제한합니다.

### 서브컬렉션 격리
`cart`, `purchased_books`, `liked_books`, `liked_feeds`는 모두 해당 유저 본인만 접근 가능합니다.
관리자도 직접 접근하지 않습니다. (탈퇴 처리는 Admin SDK로 서버에서 수행 권장)
