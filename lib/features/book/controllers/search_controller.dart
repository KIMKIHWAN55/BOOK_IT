import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';

// 도서 검색 화면용 Controller
// 전체 도서 목록을 실시간으로 가져옴
final allBooksProvider = StreamProvider.autoDispose<List<BookModel>>((ref) {
  final repository = ref.read(bookRepositoryProvider);
  return repository.getAllBooksStream();
});