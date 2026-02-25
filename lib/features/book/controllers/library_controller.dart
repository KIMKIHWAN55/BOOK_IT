import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/book_repository.dart';

// 사용자가 구매한 책 목록을 실시간으로 가져옴
final purchasedBooksProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final repository = ref.read(bookRepositoryProvider);
  return repository.getPurchasedBooksStream();
});

// 페이지 수 업데이트
final libraryControllerProvider = Provider.autoDispose((ref) {
  return LibraryController(ref);
});

class LibraryController {
  final Ref ref;
  LibraryController(this.ref);

  Future<void> updateCurrentPage(String bookId, int newPage) async {
    await ref.read(bookRepositoryProvider).updateCurrentPage(bookId, newPage);
  }
}