import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../../book/models/book_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final boardRepositoryProvider = Provider((ref) => BoardRepository());

class BoardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 게시글 조회
  Stream<List<PostModel>> getPostsStream(
      {String? userId, bool isLikedPosts = false}) {
    Query query = _firestore.collection('posts').orderBy(
        'createdAt', descending: true);

    if (isLikedPosts && userId != null) {
      // 내가 좋아요한 글 목록 조회
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

  // 좋아요 토글 (트랜잭션: 게시글 업데이트 + 내 보관함 동기화)
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
      // 내 보관함에 요약 정보 저장
      batch.set(myLikeRef, {
        'content': post.content,
        'bookTitle': post.bookTitle ?? '제목 없음',
        'bookImageUrl': post.bookImageUrl ?? '',
        'likedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

// 댓글 관련 기능
  //  댓글 /대댓글 작성
  Future<void> addComment({
    required String postId,
    required String uid,
    required String nickname,
    required String content,
    String? parentId,
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final batch = _firestore.batch();

    final commentRef = postRef.collection('comments').doc();
    batch.set(commentRef, {
      'content': content,
      'uid': uid,
      'nickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
      'parentId': parentId,
      'isDeleted': false,
    });

    batch.update(postRef, {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }
  //댓글 소프트 삭제
  Future<void> softDeleteComment(String postId, String commentId) async {
    await _firestore.collection('posts').doc(postId).collection('comments').doc(
        commentId).update({
      'content': '삭제된 댓글입니다.',
      'isDeleted': true,
    });
  }

  // 댓글 목록 조회(오래된 순)
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore.collection('posts').doc(postId).collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // 게시글 작성/수정/삭제 관련 기능
  // 게시글 저장
  Future<void> addPost(Map<String, dynamic> postData) async {
    await _firestore.collection('posts').add(postData);
  }

// 게시글 삭제 시 하위 댓글도 함께 삭제
  Future<void> deletePost(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);

    // 해당 게시글에 달린 모든 댓글 가져오기
    final commentsSnapshot = await postRef.collection('comments').get();

    final batch = _firestore.batch();

    // 게시글 본문 삭제 예약
    batch.delete(postRef);

    // 댓글들도 모두 삭제 예약
    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 한 번에(트랜잭션처럼) 실행
    await batch.commit();
  }

  // 게시글 수정
  Future<void> updatePost(String postId,
      Map<String, dynamic> updateData) async {
    await _firestore.collection('posts').doc(postId).update(updateData);
  }

  // 책 목록 조회
  Stream<List<BookModel>> getBooksStream() {
    return _firestore.collection('books').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
    });
  }

  // 책 상세 정보 가져오기
  Future<BookModel?> getBookById(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (doc.exists) {
      return BookModel.fromFirestore(doc);
    }
    return null;
  }

// 유저 닉네임 가져오기
  Future<String> getUserNickname(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data()?['nickname'] != null) {
        return doc.data()!['nickname'];
      }

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