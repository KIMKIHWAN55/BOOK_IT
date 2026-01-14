import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/book_model.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // 화폐 포맷 (예: 13,000)
    final currencyFormat = NumberFormat("#,###", "ko_KR");

    return Scaffold(
      backgroundColor: Colors.white, // Frame 180 Background
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. 배경 레이어 (Background Graphics)
          // ---------------------------------------------------------

          // [CSS Frame 38] 상단 그라디언트 배경
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF999999).withOpacity(0.6), // rgba(153, 153, 153, 0.6)
                    const Color(0xFF222222).withOpacity(0.7), // rgba(34, 34, 34, 0.7)
                  ],
                ),
              ),
            ),
          ),

          // [CSS Ellipse 74] 붉은색 블러 효과
          Positioned(
            top: 206,
            left: 1,
            right: 1, // width 388과 유사하게 맞춤
            height: 434,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Ellipse
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFF8888).withOpacity(0.2), // rgba(255, 136, 136, 0.2)
                    const Color(0xFFE3B7B7).withOpacity(0.2), // rgba(227, 183, 183, 0.2)
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65), // filter: blur(65px)
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 2. 메인 컨텐츠 (Scrollable Content)
          // ---------------------------------------------------------
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 앱바 공간 확보
                  const SizedBox(height: 50),

                  // [CSS Frame 33] 상단 네비게이션
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                        // 알림 아이콘 & 뱃지
                        Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEA4335), // Red dot
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10), // 위치 미세 조정

                  // [CSS Rectangle 5896] 책 표지 이미지 (Top 90px 위치에 해당)
                  Center(
                    child: Container(
                      width: 165,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(book.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // 책 표지 아래 여백 (Top 400px에 텍스트 시작하도록 조정)
                  const SizedBox(height: 60),

                  // -------------------------------------------------
                  // [Frame 202, 201, 200] 책 기본 정보 영역
                  // -------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목 (Paradox)
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                            letterSpacing: -0.025,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 작가 (호베루투 카를로스)
                        Text(
                          book.author,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: Color(0xFF777777),
                            letterSpacing: -0.05,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 별점 & 리뷰수 (Frame 182)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFBBC05), size: 16),
                            const SizedBox(width: 4),
                            const Text("4.8", style: TextStyle(color: Color(0xFFFBBC05), fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Text("(${book.reviewCount ?? 762})", style: const TextStyle(color: Color(0xFF767676), fontSize: 14)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 가격 정보 (Frame 199 + Frame 200)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 할인율
                            if (book.discountRate != null && book.discountRate! > 0)
                              Text(
                                "${book.discountRate}%",
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEA4335), // Red
                                ),
                              ),
                            const SizedBox(width: 8),
                            // 할인가 (판매가)
                            Text(
                              "${currencyFormat.format(book.discountedPrice)}원",
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 원래 가격 (취소선)
                            if (book.discountRate != null && book.discountRate! > 0)
                              Text(
                                "${currencyFormat.format(book.price)}원",
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  color: Color(0xFF767676),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40), // Top 570px 줄거리 위치 맞춤

                  // -------------------------------------------------
                  // [Frame 206] 줄거리 & 태그 영역
                  // -------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "줄거리",
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 부제목 (Frame 203)
                        const Text(
                          "“시간의 틈새에서 진실을 마주하다”",
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            color: Color(0xFF767676),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 본문
                        Text(
                          book.description.isNotEmpty
                              ? book.description
                              : "한 천재 과학자가 시간 여행 실험을 성공시키지만, 예상치 못한 결과로 과거의 자신과 마주하게 된다. 현재와 과거의 선택이 꼬이면서...",
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            height: 1.4,
                            color: Color(0xFF767676),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // [Frame 181] 태그 (#소설 #SF)
                        Row(
                          children: (book.tags.isNotEmpty ? book.tags : ['#소설', '#SF', '#미스테리'])
                              .map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(
                              tag.startsWith('#') ? tag : "#$tag",
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0088DD), // Blue color
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // -------------------------------------------------
                  // [Frame 184] 리뷰 헤더 & 리스트
                  // -------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "리뷰",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
                        ),
                        Text(
                          "더보기",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF767676)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  // 가로 스크롤 리뷰 리스트 (Frame 193)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        _buildReviewCard("booklover_33", "읽고 나서도 계속 머릿속에서..."),
                        const SizedBox(width: 12),
                        _buildReviewCard("reader_01", "SF적인 재미와 동시에 인간의..."),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),

                  // 하단바에 가려지지 않도록 여백 추가
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 3. [CSS Frame 198] 하단 구매 바 (Bottom Bar)
          // ---------------------------------------------------------
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100, // Safe area 포함 넉넉하게
              padding: const EdgeInsets.only(top: 18, left: 24, right: 24, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  // 좋아요 (Frame 195)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.favorite_border, color: Color(0xFFED7777), size: 24),
                      SizedBox(height: 4),
                      Text("좋아요", style: TextStyle(fontSize: 10, color: Color(0xFF222222))),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // 장바구니 (Frame 194)
                  GestureDetector(
                    onTap: () {
                      // 장바구니 담기 로직
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

                  // 구매하기 버튼 (Rectangle 5900)
                  Container(
                    width: 219,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD45858), // Red button
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "구매하기",
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  // 리뷰 카드 위젯 (CSS Frame 183 스타일)
  Widget _buildReviewCard(String user, String content) {
    return Container(
      width: 291,
      height: 147,
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
            children: [
              // 별점 5개
              for(int i=0; i<5; i++)
                const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
            ],
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
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Color(0xFF222222), height: 1.4),
          ),
        ],
      ),
    );
  }
}