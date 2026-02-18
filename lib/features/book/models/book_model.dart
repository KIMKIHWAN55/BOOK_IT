import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String rank;
  final String title;
  final String author;
  final String imageUrl;
  final String rating;
  final String reviewCount;
  final String category; // 기존 카테고리 (대분류)

  // 🔹 상세 페이지를 위해 추가된 필드들
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
    // 🔹 초기값 설정 (기존 데이터 호환성 유지)
    this.description = '',
    this.price = 0,
    this.discountRate,
    this.tags = const [],
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
      // 🔹 추가된 필드 파싱
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      discountRate: data['discountRate'], // null 가능
      tags: List<String>.from(data['tags'] ?? []),
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
      // 🔹 추가된 필드 변환
      'description': description,
      'price': price,
      'discountRate': discountRate,
      'tags': tags,
    };
  }

  // 🔹 할인가 계산 로직 (유틸리티)
  int get discountedPrice {
    if (discountRate == null || discountRate == 0) return price;
    return (price * (100 - discountRate!) / 100).round();
  }

  // 🌟 [추가됨] 리버팟 상태 관리 및 데이터 수정 시 필수 (불변 객체 패턴)
  BookModel copyWith({
    String? id,
    String? rank,
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