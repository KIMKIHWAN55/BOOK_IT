import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ★ DB 연동을 위해 추가
import '../models/book_model.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // 화폐 포맷 (예: 13,000)
    final currencyFormat = NumberFormat("#,###", "ko_KR");

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. 배경 레이어 (유지)
          // ---------------------------------------------------------
          Positioned(
            top: 0, left: 0, right: 0, height: 380,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF999999).withOpacity(0.6),
                    const Color(0xFF222222).withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 206, left: 1, right: 1, height: 434,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFF8888).withOpacity(0.2),
                    const Color(0xFFE3B7B7).withOpacity(0.2),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 2. 메인 컨텐츠
          // ---------------------------------------------------------
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),

                  // 상단 네비게이션
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                        Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                            Positioned(
                              right: 2, top: 2,
                              child: Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(color: Color(0xFFEA4335), shape: BoxShape.circle),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 책 표지 이미지 (Top 90px)
                  Center(
                    child: Container(
                      width: 165, height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25), offset: const Offset(0, 2), blurRadius: 2),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(book.imageUrl),
                          fit: BoxFit.cover,
                          // 이미지 없을 때 에러 방지
                          onError: (exception, stackTrace) {},
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 책 기본 정보 영역
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF222222), letterSpacing: -0.025),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFF777777), letterSpacing: -0.05),
                        ),
                        const SizedBox(height: 12),

                        // 별점 & 리뷰수
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFBBC05), size: 16),
                            const SizedBox(width: 4),
                            Text(book.rating, style: const TextStyle(color: Color(0xFFFBBC05), fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Text("(${book.reviewCount})", style: const TextStyle(color: Color(0xFF767676), fontSize: 14)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 가격 정보
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (book.discountRate != null && book.discountRate! > 0)
                              Text(
                                "${book.discountRate}%",
                                style: const TextStyle(fontFamily: 'Pretendard', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFEA4335)),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              "${currencyFormat.format(book.discountedPrice)}원",
                              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
                            ),
                            const SizedBox(width: 8),
                            if (book.discountRate != null && book.discountRate! > 0)
                              Text(
                                "${currencyFormat.format(book.price)}원",
                                style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, decoration: TextDecoration.lineThrough, color: Color(0xFF767676)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 줄거리 & 태그 영역
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("줄거리", style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                        const SizedBox(height: 10),

                        // 줄거리 본문
                        Text(
                          book.description.isNotEmpty ? book.description : "줄거리 정보가 없습니다.",
                          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, height: 1.4, color: Color(0xFF767676)),
                        ),
                        const SizedBox(height: 20),

                        // 태그
                        if (book.tags.isNotEmpty)
                          Wrap(
                            spacing: 10,
                            children: book.tags.map((tag) => Text(
                              tag.startsWith('#') ? tag : "#$tag",
                              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0088DD)),
                            )).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // -------------------------------------------------
                  // ★ 리뷰 영역 (DB 연동 + '리뷰 없음' 처리)
                  // -------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("리뷰", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                        Text("더보기", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF767676))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 실제 리뷰 데이터 스트림 (지금은 비어있음 -> "등록된 리뷰가 없습니다" 표시)
                  SizedBox(
                    height: 150,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('books')
                          .doc(book.id) // 현재 책의 ID
                          .collection('reviews') // 'reviews' 서브 컬렉션 조회
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        // 1. 데이터가 없거나 비어있을 때 (가장 중요한 부분!)
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            child: const Center(
                              child: Text(
                                "아직 등록된 리뷰가 없습니다.",
                                style: TextStyle(color: Color(0xFF767676), fontSize: 14),
                              ),
                            ),
                          );
                        }

                        // 2. 리뷰가 있을 때 (나중에 리뷰 기능 만들면 자동으로 뜸)
                        final reviews = snapshot.data!.docs;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final reviewData = reviews[index].data() as Map<String, dynamic>;
                            return _buildReviewCard(
                                reviewData['userName'] ?? '익명',
                                reviewData['content'] ?? ''
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 3. 하단 구매 바 (유지)
          // ---------------------------------------------------------
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.only(top: 18, left: 24, right: 24, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.favorite_border, color: Color(0xFFED7777), size: 24),
                      SizedBox(height: 4),
                      Text("좋아요", style: TextStyle(fontSize: 10, color: Color(0xFF222222))),
                    ],
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("장바구니에 담겼습니다.")));
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_cart_outlined, color: Color(0xFF222222), size: 24),
                        SizedBox(height: 4),
                        Text("장바구니", style: TextStyle(fontSize: 10, color: Color(0xFF222222))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 219, height: 52,
                    decoration: BoxDecoration(color: const Color(0xFFD45858), borderRadius: BorderRadius.circular(8)),
                    child: const Center(
                      child: Text("구매하기", style: TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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

  // 리뷰 카드 위젯
  Widget _buildReviewCard(String user, String content) {
    return Container(
      width: 291, height: 147,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [for(int i=0; i<5; i++) const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14)],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(user, style: const TextStyle(fontSize: 12, color: Color(0xFF767676))),
              const SizedBox(width: 8),
              Container(width: 1, height: 10, color: const Color(0xFFDDDDDD)),
              const SizedBox(width: 8),
              const Text("2025. 10. 10", style: TextStyle(fontSize: 12, color: Color(0xFF767676))),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Color(0xFF222222), height: 1.4)),
        ],
      ),
    );
  }
}