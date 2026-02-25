import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String uid;
  final String userName;
  final String content;
  final double rating;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.uid,
    required this.userName,
    required this.content,
    required this.rating,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'content': content,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '익명',
      content: data['content'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}