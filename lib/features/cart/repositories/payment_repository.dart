import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentRepositoryProvider = Provider.autoDispose((ref) => PaymentRepository());

class PaymentRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 일괄 결제 처리 (Batch)
  Future<void> purchaseBooks(List<Map<String, dynamic>> items) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final batch = _firestore.batch();

    for (var item in items) {
      // id가 없으면 에러가 나도록 설계해야 하지만, 방어 코드로 임시 id 생성
      final bookId = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      // 1. 🌟 내 서재(purchased_books)에 '추가' 명령
      final purchasedRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchased_books')
          .doc(bookId);

      batch.set(purchasedRef, {
        'id': bookId,
        'title': item['title'],
        'author': item['author'],
        'imageUrl': item['imageUrl'],
        'price': item['price'],
        'purchasedAt': FieldValue.serverTimestamp(),
        'currentPage': 0, // 내 서재 독서 기록용 (초기값 0)
      });

      // 2. 🌟 장바구니(cart)에서 '삭제' 명령 (결제 완료된 상품 비우기)
      final cartRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(bookId);

      batch.delete(cartRef);
    }

    // 트랜잭션/배치 일괄 커밋 (추가와 삭제가 한 번에 묶여서 실행됨)
    await batch.commit();
  }
}