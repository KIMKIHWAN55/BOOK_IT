import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../repositories/admin_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';

// 1. 책 목록을 실시간으로 감시하는 StreamProvider
// UI에서는 ref.watch(adminBooksProvider)로 사용합니다.
final adminBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getBooksStream();
});

// 2. 관리자 기능(등록, 수정, 삭제)을 담당하는 Controller Provider
// UI에서는 ref.read(adminControllerProvider.notifier)로 메서드를 호출합니다.
final adminControllerProvider = AsyncNotifierProvider<AdminController, void>(
  AdminController.new,
);

class AdminController extends AsyncNotifier<void> {

  // 초기 상태 설정 (특별한 초기값이 필요 없으므로 null 반환)
  @override
  FutureOr<void> build() {
    return null;
  }

  // Repository 접근 (ref.read를 통해 의존성 주입)
  AdminRepository get _repository => ref.read(adminRepositoryProvider);

  // ------------------------------------------------------------------------
  // 🔹 책 등록 및 수정 로직
  // ------------------------------------------------------------------------
  Future<bool> registerBook({
    required BookModel book,
    File? newImage,
    required bool isEditing,
  }) async {
    // 1. 로딩 상태로 변경
    state = const AsyncLoading();

    // 2. 비동기 작업 수행 (AsyncValue.guard가 try-catch 역할을 대신함)
    state = await AsyncValue.guard(() async {
      String imageUrl = book.imageUrl;

      // 새 이미지가 선택되었다면 스토리지에 업로드 후 URL 갱신
      if (newImage != null) {
        imageUrl = await _repository.uploadImage(newImage);

      //수정 모드인데 기존 이미지가 있었다면, 쓰레기(기존 이미지) 지우기!
      if (isEditing && book.imageUrl.isNotEmpty) {
        try {
          // repository에 만들어두신 Storage 삭제 기능 활용하거나 직접 삭제
          await FirebaseStorage.instance.refFromURL(book.imageUrl).delete();
        } catch (e) {
          print("기존 이미지 삭제 실패 (무시): $e");
        }
      }
    }

      // 이미지 URL이 업데이트된 객체 생성 (copyWith 사용)
      final updatedBook = book.copyWith(imageUrl: imageUrl);

      // 수정 모드이면 update, 아니면 add 호출
      if (isEditing) {
        await _repository.updateBook(updatedBook);
      } else {
        await _repository.addBook(updatedBook);
      }
    });

    // 3. 결과 반환 (에러가 없으면 true)
    if (state.hasError) {
      // 에러 로그 출력 (필요시 Toast나 SnackBar로 UI에 전달 가능)
      print("Register Book Error: ${state.error}");
      return false;
    }
    return true;
  }

  // ------------------------------------------------------------------------
  // 🔹 책 삭제 로직
  // ------------------------------------------------------------------------
  Future<void> deleteBook(String docId, String imageUrl) async {
    // 1. 로딩 상태로 변경
    state = const AsyncLoading();

    // 2. 삭제 작업 수행 (Firestore 문서 + Storage 이미지)
    state = await AsyncValue.guard(() async {
      await _repository.deleteBook(docId, imageUrl);
    });

    // 삭제 후 별도의 반환값은 없으며, 에러 발생 시 state.hasError로 UI에서 확인 가능
  }
  //  주간 추천 도서 업데이트 요청
  Future<void> updateRecommendedBooks(List<String> selectedBookIds) async {
    try {
      await _repository.updateWeeklyRecommend(selectedBookIds);
    } catch (e) {
      throw Exception("추천 도서 업데이트 실패: $e");
    }
  }
}