import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final int rank;
  final String title;
  final String author;
  final String imageUrl;
  final String rating;
  final String reviewCount;
  final String category; // 기존 카테고리 (대분류)
  final String description; // 줄거리
  final int price;          // 정가 (예: 13000)
  final int? discountRate;  // 할인율 (예: 20 -> 20%)
  final List<String> tags;  // 상세 태그 (예: ['#소설', '#SF', '#미스테리'])

  BookModel({
    required this.id,
    required this.rank,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.category,
    this.description = '',
    this.price = 0,
    this.discountRate,
    this.tags = const [],
  });

  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookModel(
      id: doc.id,
      rank: int.tryParse(data['rank']?.toString() ?? '0') ?? 0,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      imageUrl: data['imageUrl'] ?? '',

      // 숫자가 넘어와도 무조건 문자로 변환
      rating: data['rating']?.toString() ?? '0.0',
      reviewCount: data['reviewCount']?.toString() ?? '0',

      category: data['category'] ?? 'general',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      discountRate: data['discountRate'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
      // 🔹 추가된 필드 변환
      'description': description,
      'price': price,
      'discountRate': discountRate,
      'tags': tags,
    };
  }

  // 할인가 계산 로직
  int get discountedPrice {
    if (discountRate == null || discountRate == 0) return price;
    return (price * (100 - discountRate!) / 100).round();
  }

  BookModel copyWith({
    String? id,
    int? rank,
    String? title,
    String? author,
    String? imageUrl,
    String? rating,
    String? reviewCount,
    String? category,
    String? description,
    int? price,
    int? discountRate,
    List<String>? tags,
  }) {
    return BookModel(
      id: id ?? this.id,
      rank: rank ?? this.rank,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      discountRate: discountRate ?? this.discountRate,
      tags: tags ?? this.tags,
    );
  }
}