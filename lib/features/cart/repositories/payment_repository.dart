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
      // id가 없으면 현재 시간을 임시 id로 사용 (장바구니/상세에서 넘겨주는 것이 좋음)
      final bookId = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchased_books')
          .doc(bookId);

      batch.set(docRef, {
        'id': bookId,
        'title': item['title'],
        'author': item['author'],
        'imageUrl': item['imageUrl'],
        'price': item['price'],
        'purchasedAt': FieldValue.serverTimestamp(),
        'currentPage': 0, // 내 서재 독서 기록용 (초기값 0)
      });
    }

    // 트랜잭션/배치 일괄 커밋
    await batch.commit();
  }
}