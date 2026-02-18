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
      bookRating: (data['bookRating'] ?? 0.0).toDouble(),
      bookReviewCount: data['bookReviewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}