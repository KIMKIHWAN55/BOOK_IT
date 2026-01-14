import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 가격 콤마 포맷팅용 (pubspec.yaml에 intl 패키지 필요)
import '../models/book_model.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // 가격 포맷터 (예: 13000 -> 13,000)
    final currencyFormat = NumberFormat("#,###", "ko_KR");

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. 배경 (Background & Blur)
          Positioned.fill(
            child: Stack(
              children: [
                // 배경 이미지
                book.imageUrl.isNotEmpty
                    ? Image.network(book.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                    : Container(color: Colors.grey),
                // Blur 효과
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF999999).withOpacity(0.6),
                        const Color(0xFF222222).withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 메인 컨텐츠 (스크롤 가능)
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60), // 상단 여백

                  // 상단 네비게이션 바
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 책 표지 이미지
                  Center(
                    child: Container(
                      width: 165,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25), offset: const Offset(0, 2), blurRadius: 2),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(book.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 상세 정보 영역 (흰색 배경)
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 400,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목
                        Text(
                          book.title,
                          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
                        ),
                        const SizedBox(height: 4),
                        // 작가
                        Text(
                          book.author,
                          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFF777777)),
                        ),
                        const SizedBox(height: 12),

                        // 별점
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFBBC05), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              book.rating.isNotEmpty ? book.rating : "0.0",
                              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFFFBBC05)),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "(${book.reviewCount})",
                              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 12, color: Color(0xFF767676)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // 줄거리
                        const Text(
                          "줄거리",
                          style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          book.description.isNotEmpty ? book.description : "줄거리 정보가 없습니다.",
                          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, height: 1.4, color: Color(0xFF767676)),
                        ),

                        const SizedBox(height: 20),

                        // 태그 리스트
                        Wrap(
                          spacing: 10,
                          children: book.tags.map((tag) => _buildTag(tag)).toList(),
                        ),

                        const SizedBox(height: 100), // 하단 버튼 공간 확보
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. 하단 구매 바
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3))),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  // 가격 정보
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (book.discountRate != null && book.discountRate! > 0) ...[
                        Row(
                          children: [
                            Text("${book.discountRate}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFEA4335))),
                            const SizedBox(width: 8),
                            Text(
                              "${currencyFormat.format(book.discountedPrice)}원",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
                            ),
                          ],
                        ),
                        Text(
                          "${currencyFormat.format(book.price)}원",
                          style: const TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough, color: Color(0xFF767676)),
                        ),
                      ] else ...[
                        Text(
                          "${currencyFormat.format(book.price)}원",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
                        ),
                      ],
                    ],
                  ),

                  const Spacer(),

                  // 구매하기 버튼
                  Container(
                    width: 150, // 너비 조정
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD45858),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text("구매하기", style: TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Text(
      text.startsWith('#') ? text : "#$text",
      style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0088DD)),
    );
  }
}