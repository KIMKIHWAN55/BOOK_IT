import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';

// -----------------------------------------------------------------------------
// 도서 검색 화면용 Controller
// -----------------------------------------------------------------------------
// 전체 도서 목록을 실시간으로 가져오는 StreamProvider
// 데이터(Document)를 UI에서 쓰기 편하도록 BookModel 리스트로 변환해서 제공합니다.
final allBooksProvider = StreamProvider.autoDispose<List<BookModel>>((ref) {
  final repository = ref.read(bookRepositoryProvider);
  return repository.getAllBooksStream();
});