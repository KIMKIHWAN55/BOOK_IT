import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';

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

  // 좋아요 토글 (추가/삭제)
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
      return false; // 좋아요 해제됨
    } else {
      await ref.set({
        'title': book.title,
        'author': book.author,
        'imageUrl': book.imageUrl,
        'likedAt': FieldValue.serverTimestamp(),
      });
      return true; // 좋아요 설정됨
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

  // 리뷰 가져오기 (Stream)
  Stream<QuerySnapshot> getReviewsStream(String bookId) {
    return _firestore
        .collection('books')
        .doc(bookId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}