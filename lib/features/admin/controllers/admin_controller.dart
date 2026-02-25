import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../repositories/admin_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';

// 책 목록 실시간 StreamProvider
final adminBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getBooksStream();
});

class AdminSearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  // 검색어를 업데이트하는 메서드
  void updateQuery(String newQuery) {
    state = newQuery;
  }
}

final adminSearchQueryProvider = NotifierProvider<AdminSearchQueryNotifier, String>(
  AdminSearchQueryNotifier.new,
);

final filteredAndSortedBooksProvider = Provider<AsyncValue<List<BookModel>>>((ref) {
  final booksAsync = ref.watch(adminBooksProvider);
  final searchQuery = ref.watch(adminSearchQueryProvider).toLowerCase();

  return booksAsync.whenData((books) {
    var filteredList = books.where((book) {
      final titleMatch = book.title.toLowerCase().contains(searchQuery);
      final authorMatch = book.author.toLowerCase().contains(searchQuery);
      return titleMatch || authorMatch;
    }).toList();

    filteredList.sort((a, b) => a.rank.compareTo(b.rank));
    return filteredList;
  });
});

// 관리자 기능 Controller
final adminControllerProvider = AsyncNotifierProvider<AdminController, void>(
  AdminController.new,
);

class AdminController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  AdminRepository get _repository => ref.read(adminRepositoryProvider);

  //  책 등록 및 수정 로직
  Future<bool> registerBook({
    required BookModel book,
    File? newImage,
    required bool isEditing,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      String imageUrl = book.imageUrl;

      if (newImage != null) {
        imageUrl = await _repository.uploadImage(newImage);

        if (isEditing && book.imageUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(book.imageUrl).delete();
          } catch (e) {
            print("기존 이미지 삭제 실패 (무시): $e");
          }
        }
      }

      final updatedBook = book.copyWith(imageUrl: imageUrl);

      if (isEditing) {
        await _repository.updateBook(updatedBook);
      } else {
        await _repository.addBook(updatedBook);
      }
    });

    if (state.hasError) {
      print("Register Book Error: ${state.error}");
      return false;
    }
    return true;
  }

  //  책 삭제 로직
  Future<void> deleteBook(String docId, String imageUrl) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _repository.deleteBook(docId, imageUrl);
    });
  }

  // 주간 추천 도서 업데이트 요청
  Future<void> updateRecommendedBooks(List<String> selectedBookIds) async {
    try {
      await _repository.updateWeeklyRecommend(selectedBookIds);
    } catch (e) {
      throw Exception("추천 도서 업데이트 실패: $e");
    }
  }
}