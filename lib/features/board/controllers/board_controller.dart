import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/board_repository.dart';
import '../models/post_model.dart';
import '../../book/models/book_model.dart';

// (수정) 모두 autoDispose를 붙여서 이전 유저의 데이터가 캐싱되는 것을 막기.

//  최근 게시글 목록
final recentPostsProvider = StreamProvider.autoDispose<List<PostModel>>((ref) {
  return ref.watch(boardRepositoryProvider).getPostsStream();
});

// 내가 좋아요한 게시글 목록
final likedPostsProvider = StreamProvider.autoDispose<List<PostModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(boardRepositoryProvider).getPostsStream(userId: user.uid, isLikedPosts: true);
});

// 내가 작성한 게시글 목록
final myPostsProvider = StreamProvider.autoDispose<List<PostModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(boardRepositoryProvider).getPostsStream(userId: user.uid);
});

// 특정 게시글의 댓글 목록
final commentsProvider = StreamProvider.autoDispose.family<List<QueryDocumentSnapshot>, String>((ref, postId) {
  final repository = ref.watch(boardRepositoryProvider);
  return repository.getCommentsStream(postId).map((snapshot) => snapshot.docs);
});

// 책 목록
final booksProvider = StreamProvider.autoDispose<List<BookModel>>((ref) {
  return ref.watch(boardRepositoryProvider).getBooksStream();
});

final boardControllerProvider = Provider((ref) => BoardController(ref));

class BoardController {
  final Ref _ref;
  BoardController(this._ref);

  BoardRepository get _repository => _ref.read(boardRepositoryProvider);
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // 좋아요  로직
  Future<void> toggleLike(PostModel post) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    final isLiked = post.likedBy.contains(_currentUser!.uid);
    await _repository.toggleLike(
        post: post,
        userId: _currentUser!.uid,
        isAlreadyLiked: isLiked
    );
  }

//  댓글 작성 로직
  Future<void> addComment(String postId, String content, {String? parentId}) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    final nickname = await _repository.getUserNickname(_currentUser!.uid);

    await _repository.addComment(
      postId: postId,
      uid: _currentUser!.uid,
      nickname: nickname,
      content: content,
      parentId: parentId,
    );
  }

  // 댓글 삭제 로직
  Future<void> deleteComment(String postId, String commentId) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");
    await _repository.softDeleteComment(postId, commentId);
  }

  // 게시글 작성 기능
  Future<void> writePost({
    required String content,
    required BookModel book,
  }) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    //닉네임 가져오기
    final nickname = await _repository.getUserNickname(_currentUser!.uid);

    // 해시태그 추출 및 병합
    List<String> tags = _extractHashTags(content);
    if (book.tags.isNotEmpty) {
      tags.addAll(book.tags);
    }
    final finalTags = tags.toSet().toList(); // 중복 제거

    // 데이터 생성
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

    // 저장 요청
    await _repository.addPost(postData);
  }

  // 게시글 삭제 로직
  Future<void> deletePost(String postId) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    // 레포에 삭제 위임
    await _repository.deletePost(postId);
  }

  // 게시글 수정 로직
  Future<void> updatePost({
    required String postId,
    required String content,
    BookModel? book, // 수정 시 책을 변경할 수도 있고 안 할 수도 있으므로 nullable
  }) async {
    if (_currentUser == null) throw Exception("로그인이 필요합니다.");

    // 내용이 바뀌면 해시태그 다시 추출
    List<String> tags = _extractHashTags(content);
    if (book != null && book.tags.isNotEmpty) {
      tags.addAll(book.tags);
    }
    final finalTags = tags.toSet().toList();

    // 업데이트할 데이터 구성
    final Map<String, dynamic> updateData = {
      'content': content,
      'tags': finalTags,
      'updatedAt': FieldValue.serverTimestamp(), // 수정된 시간 기록
    };

    // 만약 책 정보도 변경했다면 추가로 업데이트
    if (book != null) {
      updateData['bookId'] = book.id;
      updateData['bookTitle'] = book.title;
      updateData['bookAuthor'] = book.author;
      updateData['bookImageUrl'] = book.imageUrl;
      updateData['bookRating'] = book.rating;
      updateData['bookReviewCount'] = book.reviewCount;
    }

    // DB 업데이트 요청
    await _repository.updatePost(postId, updateData);
  }

  // 책 상세 정보 가져오기
  Future<BookModel?> getBookDetail(String bookId) async {
    return await _repository.getBookById(bookId);
  }

  List<String> _extractHashTags(String text) {
    final RegExp regex = RegExp(r"\#([^\s]+)");
    final Iterable<Match> matches = regex.allMatches(text);
    return matches.map((m) => "#${m.group(1)}").toList();
  }
}