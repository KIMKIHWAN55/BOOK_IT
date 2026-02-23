import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../../book/models/book_model.dart'; // BookModel import 확인
import 'package:firebase_auth/firebase_auth.dart';

// 🌟 [중요] 이 Provider 선언이 있어야 Controller에서 에러가 안 납니다!
final boardRepositoryProvider = Provider((ref) => BoardRepository());

class BoardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ======================================================================
  // 1. 게시글 조회 (메인, 좋아요한 글, 내가 쓴 글)
  // ======================================================================
  Stream<List<PostModel>> getPostsStream(
      {String? userId, bool isLikedPosts = false}) {
    Query query = _firestore.collection('posts').orderBy(
        'createdAt', descending: true);

    if (isLikedPosts && userId != null) {
      // 내가 좋아요한 글 목록 조회 (likedBy 배열에 내 ID가 있는 글)
      query = _firestore.collection('posts')
          .where('likedBy', arrayContains: userId)
          .orderBy('createdAt', descending: true);
    } else if (userId != null) {
      // 내가 쓴 글 목록 조회
      query = query.where('uid', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  // ======================================================================
  // 2. 좋아요 토글 (트랜잭션: 게시글 업데이트 + 내 보관함 동기화)
  // ======================================================================
  Future<void> toggleLike({
    required PostModel post,
    required String userId,
    required bool isAlreadyLiked,
  }) async {
    final postRef = _firestore.collection('posts').doc(post.id);
    final myLikeRef = _firestore.collection('users').doc(userId).collection(
        'liked_feeds').doc(post.id);

    final batch = _firestore.batch();

    if (isAlreadyLiked) {
      // 좋아요 취소
      batch.update(postRef, {
        'likeCount': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
      // 내 보관함에서 삭제
      batch.delete(myLikeRef);
    } else {
      // 좋아요 추가
      batch.update(postRef, {
        'likeCount': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
      // 내 보관함에 요약 정보 저장 (마이페이지 연동용)
      batch.set(myLikeRef, {
        'content': post.content,
        'bookTitle': post.bookTitle ?? '제목 없음',
        'bookImageUrl': post.bookImageUrl ?? '',
        'likedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ======================================================================
// 3. 댓글 관련 기능
  // ======================================================================
  // 🌟 댓글 & 대댓글 작성 (parentId가 있으면 대댓글)
  Future<void> addComment({
    required String postId,
    required String uid,
    required String nickname,
    required String content,
    String? parentId, // 대댓글용 부모 ID
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final batch = _firestore.batch();

    final commentRef = postRef.collection('comments').doc();
    batch.set(commentRef, {
      'content': content,
      'uid': uid,
      'nickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
      'parentId': parentId, // 부모가 없으면 null (일반 댓글)
      'isDeleted': false, // 삭제 여부
    });

    batch.update(postRef, {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // 🌟 [추가됨] 댓글 소프트 삭제 (내용만 가리기)
  Future<void> softDeleteComment(String postId, String commentId) async {
    await _firestore.collection('posts').doc(postId).collection('comments').doc(
        commentId).update({
      'content': '삭제된 댓글입니다.',
      'isDeleted': true,
    });
  }

  // 댓글 목록 조회 (오래된 순)
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore.collection('posts').doc(postId).collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ======================================================================
  // 4. 게시글 작성/수정/삭제 관련 기능
  // ======================================================================
  // 게시글 저장
  Future<void> addPost(Map<String, dynamic> postData) async {
    await _firestore.collection('posts').add(postData);
  }

// 🌟 [업그레이드된 삭제 로직] 게시글 삭제 시 하위 댓글도 함께 깔끔하게 청소!
  Future<void> deletePost(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);

    // 1. 해당 게시글에 달린 모든 댓글 가져오기
    final commentsSnapshot = await postRef.collection('comments').get();

    final batch = _firestore.batch();

    // 2. 게시글 본문 삭제 예약
    batch.delete(postRef);

    // 3. 댓글들도 모두 삭제 예약
    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 4. 한 번에(트랜잭션처럼) 실행!
    await batch.commit();
  }

  // 🌟 [추가됨] 게시글 수정
  Future<void> updatePost(String postId,
      Map<String, dynamic> updateData) async {
    await _firestore.collection('posts').doc(postId).update(updateData);
  }

  // 책 목록 조회 (글쓰기 시 책 선택용)
  Stream<List<BookModel>> getBooksStream() {
    return _firestore.collection('books').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
    });
  }

  // ======================================================================
  // 5. 기타 유틸리티
  // ======================================================================
  // 책 상세 정보 가져오기 (상세 페이지 이동용)
  Future<BookModel?> getBookById(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (doc.exists) {
      return BookModel.fromFirestore(doc);
    }
    return null;
  }

// 유저 닉네임 가져오기 (구글 이름 우선 활용)
  Future<String> getUserNickname(String uid) async {
    try {
      // 🌟 [수정] 1순위: 무조건 DB(Firestore)를 먼저 확인합니다.
      // 사용자가 앱에서 수정한 '최신 닉네임'이 여기에 있기 때문입니다.
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data()?['nickname'] != null) {
        return doc.data()!['nickname']; // DB에 설정된 닉네임 반환
      }

      // 2순위: 만약 DB에 정보가 없다면, 그때 구글 계정 이름을 확인합니다.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        return currentUser.displayName ?? '익명';
      }

      return '익명';
    } catch (e) {
      return '익명';
    }
  }
}