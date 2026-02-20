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

  // 🌟 [추가됨] 수정된 시간을 담을 필드 (수정 안 한 글도 있으니 nullable(?)로 선언)
  final DateTime? updatedAt;

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
    this.updatedAt, // 🌟 [추가됨]
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

      // 🌟 글자(String)로 들어오든 숫자(int/double)로 들어오든 안전하게 숫자로 변환
      bookRating: double.tryParse(data['bookRating']?.toString() ?? '0') ?? 0.0,
      bookReviewCount: int.tryParse(data['bookReviewCount']?.toString() ?? '0') ?? 0,
      likeCount: int.tryParse(data['likeCount']?.toString() ?? '0') ?? 0,
      commentCount: int.tryParse(data['commentCount']?.toString() ?? '0') ?? 0,

      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // 🌟 [추가됨] Firestore의 updatedAt을 DateTime으로 변환 (없으면 null 반환)
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}