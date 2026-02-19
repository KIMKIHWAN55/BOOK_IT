import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String uid;
  final String nickname;
  final String content;
  final List<String> tags;
  final String? bookId;
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookImageUrl;
  final double bookRating;
  final int bookReviewCount;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.content,
    required this.tags,
    this.bookId,
    this.bookTitle,
    this.bookAuthor,
    this.bookImageUrl,
    this.bookRating = 0.0,
    this.bookReviewCount = 0,
    required this.likeCount,
    required this.commentCount,
    required this.likedBy,
    required this.createdAt,
  });

  // Firestore 데이터를 객체로 변환
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? '익명',
      content: data['content'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      bookId: data['bookId'],
      bookTitle: data['bookTitle'],
      bookAuthor: data['bookAuthor'],
      bookImageUrl: data['bookImageUrl'],

      // 🌟 [수정됨] 글자(String)로 들어오든 숫자(int/double)로 들어오든 안전하게 숫자로 변환
      bookRating: double.tryParse(data['bookRating']?.toString() ?? '0') ?? 0.0,

      // 🌟 [추가 팁] 리뷰 카운트나 다른 숫자들도 비슷하게 처리해주면 훨씬 안전합니다.
      bookReviewCount: int.tryParse(data['bookReviewCount']?.toString() ?? '0') ?? 0,
      likeCount: int.tryParse(data['likeCount']?.toString() ?? '0') ?? 0,
      commentCount: int.tryParse(data['commentCount']?.toString() ?? '0') ?? 0,

      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}