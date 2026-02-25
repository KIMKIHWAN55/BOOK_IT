import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../../board/models/review_model.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository();
});

class BookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 좋아요 상태 확인
  Future<bool> checkLiked(String bookId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_books')
        .doc(bookId)
        .get();
    return doc.exists;
  }

  // 구매 여부 확인
  Future<bool> checkPurchased(String bookId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchased_books')
        .doc(bookId)
        .get();
    return doc.exists;
  }

  // 좋아요  (추가/삭제)
  Future<bool> toggleLike({required BookModel book, required bool isCurrentlyLiked}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_books')
        .doc(book.id);

    if (isCurrentlyLiked) {
      await ref.delete();
      return false;
    } else {
      await ref.set({
        'title': book.title,
        'author': book.author,
        'imageUrl': book.imageUrl,
        'likedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
  }

  // 장바구니 담기
  Future<void> addToCart(BookModel book) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(book.id)
        .set({
      'id': book.id,
      'title': book.title,
      'author': book.author,
      'imageUrl': book.imageUrl,
      'originalPrice': book.price,
      'discountedPrice': book.discountedPrice,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // 리뷰 가져오기
  Stream<QuerySnapshot> getReviewsStream(String bookId) {
    return _firestore
        .collection('books')
        .doc(bookId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 전체 도서 목록 가져오기
  Stream<List<BookModel>> getAllBooksStream() {
    return _firestore.collection('books').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
    });
  }

  // 내 서재 목록 가져오기
  Stream<QuerySnapshot> getPurchasedBooksStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchased_books')
        .orderBy('purchasedAt', descending: true)
        .snapshots();
  }

  // 독서 기록 업데이트
  Future<void> updateCurrentPage(String bookId, int newPage) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchased_books')
        .doc(bookId)
        .update({'currentPage': newPage});
  }

  //  카테고리 도서 목록 가져오기
  Stream<List<BookModel>> getBooksByCategoryStream(String category) {
    return _firestore
        .collection('books')
        .where('tags', arrayContains: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
    });
  }

  // 리뷰 등록 및 평점/리뷰 수 동기화 (트랜잭션 처리)
  Future<void> addReview({
    required String bookId,
    required ReviewModel review,
  }) async {
    final bookRef = _firestore.collection('books').doc(bookId);
    final reviewRef = bookRef.collection('reviews').doc(); // 새 리뷰 문서 ID 자동 생성

    await _firestore.runTransaction((transaction) async {
      final bookSnapshot = await transaction.get(bookRef);

      if (!bookSnapshot.exists) {
        throw Exception("책 데이터가 존재하지 않습니다.");
      }

      final data = bookSnapshot.data() as Map<String, dynamic>;

      double currentRating = double.tryParse(data['rating']?.toString() ?? '0.0') ?? 0.0;
      int currentReviewCount = int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0;
      //평점계산
      double newRating = ((currentRating * currentReviewCount) + review.rating) / (currentReviewCount + 1);
      // 리뷰 데이터 저장
      transaction.set(reviewRef, review.toMap());

      // 책의 평점과 리뷰 개수 동시 업데이트
      transaction.update(bookRef, {
        'rating': newRating.toStringAsFixed(1), // 예: "4.5"
        'reviewCount': (currentReviewCount + 1).toString(), // 예: "15"
      });
    });
  }
}