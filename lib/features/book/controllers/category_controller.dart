import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../repositories/book_repository.dart';

// 카테고리 결과 화면용 Controller
final categoryBooksProvider = StreamProvider.autoDispose.family<List<BookModel>, String>((ref, category) {
  final repository = ref.read(bookRepositoryProvider);
  return repository.getBooksByCategoryStream(category);
});