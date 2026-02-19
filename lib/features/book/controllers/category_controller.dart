import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';

// -----------------------------------------------------------------------------
// 카테고리 결과 화면용 Controller
// -----------------------------------------------------------------------------
// 선택된 카테고리 문자열(category)을 파라미터로 받아서 실시간 스트림을 제공합니다.
final categoryBooksProvider = StreamProvider.autoDispose.family<List<BookModel>, String>((ref, category) {
  final repository = ref.read(bookRepositoryProvider);
  return repository.getBooksByCategoryStream(category);
});