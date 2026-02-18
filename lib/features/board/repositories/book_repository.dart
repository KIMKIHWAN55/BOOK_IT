import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';

final bookRepositoryProvider = Provider((ref) => BookRepository());

class BookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🌟 리뷰 등록 및 평점 업데이트 (트랜잭션)
  Future<void> addReview({
    required String bookId,
    required ReviewModel review,
  }) async {
    final bookRef = _firestore.collection('books').doc(bookId);
    final reviewRef = bookRef.collection('reviews').doc(); // 문서 ID 자동 생성

    await _firestore.runTransaction((transaction) async {
      final bookSnapshot = await transaction.get(bookRef);

      if (!bookSnapshot.exists) {
        throw Exception("책 데이터가 존재하지 않습니다.");
      }

      // 1. 기존 평점 정보 가져오기
      final data = bookSnapshot.data() as Map<String, dynamic>;
      // 기존 값이 문자열일 수도, 숫자일 수도 있으므로 안전하게 파싱
      double currentRating = double.tryParse(data['rating']?.toString() ?? '0.0') ?? 0.0;
      int currentReviewCount = int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0;

      // 2. 새로운 평균 평점 계산
      // 공식: (기존총점 + 내점수) / (기존개수 + 1)
      double newRating = ((currentRating * currentReviewCount) + review.rating) / (currentReviewCount + 1);

      // 3. 리뷰 저장
      transaction.set(reviewRef, review.toMap());

      // 4. 책 정보 업데이트 (평점 소수점 1자리, 리뷰 수 +1)
      transaction.update(bookRef, {
        'rating': double.parse(newRating.toStringAsFixed(1)), // 숫자로 저장 추천 (혹은 문자열 유지 시 toStringAsFixed만)
        'reviewCount': currentReviewCount + 1, // 숫자로 저장 추천
      });
    });
  }
}