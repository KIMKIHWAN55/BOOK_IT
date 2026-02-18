import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/board_repository.dart';
import '../models/post_model.dart';
import '../../book/models/book_model.dart';

// [Provider] 최근 게시글 목록
final recentPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.read(boardRepositoryProvider).getPostsStream();
});

// [Provider] 내가 좋아요한 게시글 목록
final likedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.read(boardRepositoryProvider).getPostsStream(userId: user.uid, isLikedPosts: true);
});

// [Provider] 내가 작성한 게시글 목록
final myPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.read(boardRepositoryProvider).getPostsStream(userId: user.uid);
});

// [Provider] 특정 게시글의 댓글 목록
final commentsProvider = StreamProvider.family<List<QueryDocumentSnapshot>, String>((ref, postId) {
  final repository = ref.watch(boardRepositoryProvider);
  return repository.getCommentsStream(postId).map((snapshot) => snapshot.docs);
});

// [Provider] 책 목록 (글쓰기 화면의 책 선택용)
final booksProvider = StreamProvider<List<BookModel>>((ref) {
  return ref.read(boardRepositoryProvider).getBooksStream();
});

// [Provider] BoardController
final boardControllerProvider = Provider((ref) => BoardController(ref));

class BoardController {
  final Ref _ref;
  BoardController(this._ref);

  BoardRepository get _repository => _ref.read(boardRepositoryProvider);
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // 1. 좋아요 토글 로직
  Future<void> toggleLike(PostModel post) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    final isLiked = post.likedBy.contains(_currentUser!.uid);
    await _repository.toggleLike(
        post: post,
        userId: _currentUser!.uid,
        isAlreadyLiked: isLiked
    );
  }

  // 2. 댓글 작성 로직
  Future<void> addComment(String postId, String content) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    // 사용자 닉네임 가져오기
    final nickname = await _repository.getUserNickname(_currentUser!.uid);

    await _repository.addComment(
        postId: postId,
        uid: _currentUser!.uid,
        nickname: nickname,
        content: content
    );
  }

  // 3. 🌟 [누락되었던 부분] 게시글 작성 기능
  Future<void> writePost({
    required String content,
    required BookModel book,
  }) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    // (1) 닉네임 가져오기
    final nickname = await _repository.getUserNickname(_currentUser!.uid);

    // (2) 해시태그 추출 및 병합
    List<String> tags = _extractHashTags(content);
    if (book.tags.isNotEmpty) {
      tags.addAll(book.tags);
    }
    final finalTags = tags.toSet().toList(); // 중복 제거

    // (3) 데이터 생성
    final postData = {
      'uid': _currentUser!.uid,
      'nickname': nickname,
      'content': content,

      // 선택된 책 정보
      'bookId': book.id,
      'bookTitle': book.title,
      'bookAuthor': book.author,
      'bookImageUrl': book.imageUrl,
      'bookRating': book.rating,
      'bookReviewCount': book.reviewCount,

      'tags': finalTags,
      'likeCount': 0,
      'commentCount': 0,
      'likedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    };

    // (4) 저장 요청
    await _repository.addPost(postData);
  }

  // 4. 책 상세 정보 가져오기
  Future<BookModel?> getBookDetail(String bookId) async {
    return await _repository.getBookById(bookId);
  }

  // 🔹 [Private Helper] 해시태그 추출
  List<String> _extractHashTags(String text) {
    final RegExp regex = RegExp(r"\#([^\s]+)");
    final Iterable<Match> matches = regex.allMatches(text);
    return matches.map((m) => "#${m.group(1)}").toList();
  }
}