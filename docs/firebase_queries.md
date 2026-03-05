# Firestore 쿼리 명세

> BookIt 프로젝트에서 사용하는 Firestore 쿼리 패턴과 필요 인덱스를 정의합니다.
> 각 쿼리는 어느 Repository에서 사용되는지 함께 기재합니다.

---

## 목차
1. [users 쿼리](#1-users-쿼리)
2. [books 쿼리](#2-books-쿼리)
3. [posts 쿼리](#3-posts-쿼리)
4. [서브컬렉션 쿼리](#4-서브컬렉션-쿼리)
5. [복합 인덱스 목록](#5-복합-인덱스-목록)

---

## 1. users 쿼리

### 1.1 단일 유저 조회

**파일:** `auth_service.dart`, `profile_repository.dart`

```dart
// 유저 문서 단건 조회 (1회성)
FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();

// 유저 문서 실시간 구독 (프로필 화면)
FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .snapshots();
```

---

### 1.2 이메일 중복 확인

**파일:** `auth_service.dart` — `isEmailDuplicate()`

```dart
FirebaseFirestore.instance
    .collection('users')
    .where('email', isEqualTo: email)
    .limit(1)
    .get();
```

---

### 1.3 닉네임 중복 확인

**파일:** `auth_service.dart` — `isNicknameDuplicate()`
**파일:** `profile_repository.dart` — `checkNicknameDuplicate()`

```dart
FirebaseFirestore.instance
    .collection('users')
    .where('nickname', isEqualTo: nickname)
    .get();

// profile_repository: 본인 UID 제외 후 중복 판단
// query.docs.where((doc) => doc.id != currentUserUid)
```

---

### 1.4 아이디 찾기 (이름 + 전화번호)

**파일:** `auth_service.dart` — `findUserId()`

```dart
FirebaseFirestore.instance
    .collection('users')
    .where('name', isEqualTo: name)
    .where('phone', isEqualTo: phone)
    .limit(1)
    .get();
```

> 복합 필터 쿼리 — 복합 인덱스 필요 (`name` ASC + `phone` ASC)

---

### 1.5 비밀번호 찾기 (이름 + 이메일)

**파일:** `auth_service.dart` — `checkUserExists()`

```dart
FirebaseFirestore.instance
    .collection('users')
    .where('name', isEqualTo: name)
    .where('email', isEqualTo: email)
    .limit(1)
    .get();
```

---

### 1.6 유저 닉네임 단건 조회

**파일:** `board_repository.dart` — `getUserNickname()`

```dart
FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();
// doc.data()['nickname'] 추출
```

---

## 2. books 쿼리

### 2.1 전체 도서 목록 실시간 구독

**파일:** `book_repository.dart`, `board_repository.dart`

```dart
FirebaseFirestore.instance
    .collection('books')
    .snapshots();
// → List<BookModel> 변환
```

---

### 2.2 카테고리(태그)별 도서 필터

**파일:** `book_repository.dart` — `getBooksByCategoryStream()`

```dart
FirebaseFirestore.instance
    .collection('books')
    .where('tags', arrayContains: category)
    .snapshots();
```

---

### 2.3 도서 단건 조회

**파일:** `board_repository.dart`, `profile_repository.dart`

```dart
FirebaseFirestore.instance
    .collection('books')
    .doc(bookId)
    .get();
```

---

### 2.4 리뷰 목록 실시간 구독 (최신순)

**파일:** `book_repository.dart` — `getReviewsStream()`

```dart
FirebaseFirestore.instance
    .collection('books')
    .doc(bookId)
    .collection('reviews')
    .orderBy('createdAt', descending: true)
    .snapshots();
```

---

### 2.5 리뷰 등록 + 평점 동기화 (Transaction)

**파일:** `book_repository.dart` — `addReview()`

```dart
FirebaseFirestore.instance.runTransaction((transaction) async {
    // 1. 현재 도서 데이터 읽기
    final bookSnapshot = await transaction.get(bookRef);
    final currentRating = bookSnapshot.data()['rating'];
    final currentReviewCount = bookSnapshot.data()['reviewCount'];

    // 2. 평균 평점 계산
    final newRating = (currentRating * currentReviewCount + newRating)
                      / (currentReviewCount + 1);

    // 3. 리뷰 문서 생성
    transaction.set(reviewRef, review.toMap());

    // 4. 도서 평점/리뷰수 업데이트
    transaction.update(bookRef, {
        'rating': newRating.toStringAsFixed(1),
        'reviewCount': (currentReviewCount + 1).toString(),
    });
});
```

---

## 3. posts 쿼리

### 3.1 전체 게시글 실시간 구독 (최신순)

**파일:** `board_repository.dart` — `getPostsStream()`

```dart
FirebaseFirestore.instance
    .collection('posts')
    .orderBy('createdAt', descending: true)
    .snapshots();
```

---

### 3.2 내가 쓴 글 조회

**파일:** `board_repository.dart` — `getPostsStream(userId: uid)`

```dart
FirebaseFirestore.instance
    .collection('posts')
    .where('uid', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .snapshots();
```

> 복합 인덱스 필요: `uid` ASC + `createdAt` DESC

---

### 3.3 내가 좋아요한 게시글 조회

**파일:** `board_repository.dart` — `getPostsStream(isLikedPosts: true)`

```dart
FirebaseFirestore.instance
    .collection('posts')
    .where('likedBy', arrayContains: userId)
    .orderBy('createdAt', descending: true)
    .snapshots();
```

> 복합 인덱스 필요: `likedBy` ARRAY + `createdAt` DESC

---

### 3.4 게시글 작성

**파일:** `board_repository.dart` — `addPost()`

```dart
FirebaseFirestore.instance
    .collection('posts')
    .add(postData);
// 자동 ID 생성
```

---

### 3.5 게시글 수정

**파일:** `board_repository.dart` — `updatePost()`

```dart
FirebaseFirestore.instance
    .collection('posts')
    .doc(postId)
    .update(updateData);
// updateData에 updatedAt: FieldValue.serverTimestamp() 포함
```

---

### 3.6 게시글 삭제 (하위 댓글 포함 Batch)

**파일:** `board_repository.dart` — `deletePost()`

```dart
// 1. 댓글 전체 조회
final commentsSnapshot = await postRef.collection('comments').get();

final batch = FirebaseFirestore.instance.batch();

// 2. 게시글 삭제 예약
batch.delete(postRef);

// 3. 모든 댓글 삭제 예약
for (var doc in commentsSnapshot.docs) {
    batch.delete(doc.reference);
}

// 4. 원자적 실행
await batch.commit();
```

---

### 3.7 게시글 좋아요 토글 (Batch)

**파일:** `board_repository.dart` — `toggleLike()`

```dart
final batch = FirebaseFirestore.instance.batch();

// 좋아요 추가
batch.update(postRef, {
    'likeCount': FieldValue.increment(1),
    'likedBy': FieldValue.arrayUnion([userId]),
});
batch.set(myLikeRef, {
    'content': post.content,
    'bookTitle': post.bookTitle,
    'bookImageUrl': post.bookImageUrl,
    'likedAt': FieldValue.serverTimestamp(),
});

// 좋아요 취소
batch.update(postRef, {
    'likeCount': FieldValue.increment(-1),
    'likedBy': FieldValue.arrayRemove([userId]),
});
batch.delete(myLikeRef);

await batch.commit();
```

---

### 3.8 댓글 목록 실시간 구독 (오래된 순)

**파일:** `board_repository.dart` — `getCommentsStream()`

```dart
FirebaseFirestore.instance
    .collection('posts')
    .doc(postId)
    .collection('comments')
    .orderBy('createdAt', descending: false)
    .snapshots();
```

---

### 3.9 댓글 작성 (Batch — commentCount 동기화)

**파일:** `board_repository.dart` — `addComment()`

```dart
final batch = FirebaseFirestore.instance.batch();

batch.set(commentRef, {
    'content': content,
    'uid': uid,
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'parentId': parentId,   // 대댓글이면 부모 ID, 최상위면 null
    'isDeleted': false,
});

batch.update(postRef, {
    'commentCount': FieldValue.increment(1),
});

await batch.commit();
```

---

### 3.10 댓글 소프트 삭제 (Batch — commentCount 동기화)

**파일:** `board_repository.dart` — `softDeleteComment()`

```dart
final batch = FirebaseFirestore.instance.batch();

batch.update(commentRef, {
    'content': '삭제된 댓글입니다.',
    'isDeleted': true,
});

batch.update(postRef, {
    'commentCount': FieldValue.increment(-1),
});

await batch.commit();
```

---

## 4. 서브컬렉션 쿼리

### 4.1 장바구니 목록 실시간 구독

**파일:** `cart_repository.dart`

```dart
FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('cart')
    .orderBy('addedAt', descending: true)
    .snapshots();
```

---

### 4.2 장바구니 담기

**파일:** `book_repository.dart` — `addToCart()`

```dart
FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('cart').doc(book.id)
    .set({
        'id': book.id,
        'title': book.title,
        'author': book.author,
        'imageUrl': book.imageUrl,
        'originalPrice': book.price,
        'discountedPrice': book.discountedPrice,
        'addedAt': FieldValue.serverTimestamp(),
    });
// 문서 ID를 bookId로 고정 → 동일 도서 중복 담기 방지
```

---

### 4.3 장바구니 아이템 삭제

**파일:** `cart_repository.dart`

```dart
FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('cart').doc(docId)
    .delete();
```

---

### 4.4 결제 처리 — 구매 등록 + 장바구니 삭제 (Batch)

**파일:** `payment_repository.dart` — `purchaseBooks()`

```dart
final batch = FirebaseFirestore.instance.batch();

for (var item in items) {
    // 내 서재에 추가
    batch.set(purchasedRef, {
        'id': bookId,
        'title': item['title'],
        'author': item['author'],
        'imageUrl': item['imageUrl'],
        'price': item['price'],
        'purchasedAt': FieldValue.serverTimestamp(),
        'currentPage': 0,
    });

    // 장바구니에서 삭제
    batch.delete(cartRef);
}

await batch.commit();
```

---

### 4.5 도서 좋아요 상태 확인

**파일:** `book_repository.dart` — `checkLiked()`

```dart
FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('liked_books').doc(bookId)
    .get();
// doc.exists 로 좋아요 여부 판단
```

---

### 4.6 도서 좋아요 토글

**파일:** `book_repository.dart` — `toggleLike()`

```dart
// 좋아요 추가
ref.set({
    'title': book.title,
    'author': book.author,
    'imageUrl': book.imageUrl,
    'likedAt': FieldValue.serverTimestamp(),
});

// 좋아요 취소
ref.delete();
```

---

### 4.7 좋아요한 책 목록 실시간 구독

**파일:** `profile_repository.dart`

```dart
FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('liked_books')
    .orderBy('likedAt', descending: true)
    .snapshots();
```

---

### 4.8 내 서재(구매 도서) 목록 실시간 구독

**파일:** `book_repository.dart` — `getPurchasedBooksStream()`

```dart
FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('purchased_books')
    .orderBy('purchasedAt', descending: true)
    .snapshots();
```

---

### 4.9 독서 기록 업데이트 (현재 페이지)

**파일:** `book_repository.dart` — `updateCurrentPage()`

```dart
FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('purchased_books').doc(bookId)
    .update({'currentPage': newPage});
```

---

### 4.10 구매 여부 확인

**파일:** `book_repository.dart` — `checkPurchased()`

```dart
FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('purchased_books').doc(bookId)
    .get();
// doc.exists 로 구매 여부 판단
```

---

### 4.11 회원 탈퇴 — 서브컬렉션 전체 삭제

**파일:** `profile_repository.dart` — `deleteAccount()`

```dart
// 삭제 대상 서브컬렉션 목록
const subcollections = ['cart', 'liked_books', 'liked_feeds', 'purchased_books'];

for (final sub in subcollections) {
    final snapshot = await userRef.collection(sub).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
    }
    if (snapshot.docs.isNotEmpty) await batch.commit();
}

// users 문서 삭제 → Firebase Auth 계정 삭제
await userRef.delete();
await user.delete();
```

---

## 5. 복합 인덱스 목록

Firestore에서 복합 필터 + 정렬을 동시에 사용하는 쿼리는 Firebase Console에서 복합 인덱스를 생성해야 합니다.

| 컬렉션 | 필드 1 | 정렬 | 필드 2 | 정렬 | 용도 |
|--------|--------|------|--------|------|------|
| `posts` | `uid` | ASC | `createdAt` | DESC | 내가 쓴 글 조회 |
| `posts` | `likedBy` | ARRAY | `createdAt` | DESC | 내가 좋아요한 글 조회 |
| `users` | `name` | ASC | `phone` | ASC | 아이디 찾기 |
| `users` | `name` | ASC | `email` | ASC | 비밀번호 찾기 (유저 존재 확인) |

> 단일 필드 `orderBy`만 사용하는 서브컬렉션 쿼리 (`addedAt`, `purchasedAt`, `likedAt`, `createdAt`)는
> 자동 단일 인덱스로 처리되므로 별도 생성 불필요합니다.
