import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String rank;
  final String title;
  final String author;
  final String imageUrl;
  final String rating;
  final String reviewCount;
  final String category;

  BookModel({
    required this.id,
    required this.rank,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.category,
  });

  // 🔸 Firestore JSON 데이터를 객체로 변환
  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookModel(
      id: doc.id,
      rank: data['rank'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: data['rating'] ?? '0.0',
      reviewCount: data['reviewCount'] ?? '0',
      category: data['category'] ?? 'general',
    );
  }

  // 🔸 객체를 Firestore JSON 형식으로 변환 (데이터 업로드용)
  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
    };
  }
}