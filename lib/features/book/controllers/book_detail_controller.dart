import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';

//좋아요 상태 관리
final likeStatusProvider =
AsyncNotifierProvider.autoDispose.family<LikeStatusNotifier, bool, String>(
  LikeStatusNotifier.new,
);

class LikeStatusNotifier extends AsyncNotifier<bool> {
  LikeStatusNotifier(this.bookId);
  final String bookId;

  late final BookRepository _repository;

  @override
  Future<bool> build() async {
    _repository = ref.read(bookRepositoryProvider);
    return _repository.checkLiked(bookId);
  }

  Future<void> toggleLike(BookModel book) async {
    final currentState = state.value ?? false;
    state = AsyncValue.data(!currentState);

    try {
      final newState = await _repository.toggleLike(
        book: book,
        isCurrentlyLiked: currentState,
      );
      state = AsyncValue.data(newState);
    } catch (_) {
      state = AsyncValue.data(currentState);
    }
  }
}

// 구매 여부 상태 관리
final purchaseStatusProvider = FutureProvider.autoDispose.family<bool, String>((ref, bookId) {
  final repository = ref.read(bookRepositoryProvider);
  return repository.checkPurchased(bookId);
});

// 리뷰 스트림
final bookReviewsProvider = StreamProvider.autoDispose.family<dynamic, String>((ref, bookId) {
  final repository = ref.read(bookRepositoryProvider);
  return repository.getReviewsStream(bookId);
});

//  장바구니 컨트롤러
final cartControllerProvider = Provider.autoDispose((ref) {
  return CartController(ref);
});

class CartController {
  final Ref ref;
  CartController(this.ref);

  Future<void> addToCart(BookModel book) async {
    final repository = ref.read(bookRepositoryProvider);
    await repository.addToCart(book);
  }
}