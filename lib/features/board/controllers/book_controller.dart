import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/repositories/book_repository.dart';
import '../models/review_model.dart';

final bookControllerProvider = Provider((ref) => BookController(ref));

class BookController {
  final Ref _ref;
  BookController(this._ref);

  BookRepository get _repository => _ref.read(bookRepositoryProvider);
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // 리뷰 제출 로직
  Future<void> submitReview({
    required String bookId,
    required String content,
    required double rating,
  }) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    // 유저 정보
    final String userName = _currentUser!.displayName ?? '익명';

    // 모델 생성
    final review = ReviewModel(
      id: '', // ID는 Repo에서 자동 생성됨
      uid: _currentUser!.uid,
      userName: userName,
      content: content,
      rating: rating,
      createdAt: DateTime.now(),
    );

    // Repository 호출
    await _repository.addReview(bookId: bookId, review: review);
  }
}