import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/custom_network_image.dart';

import '../models/book_model.dart';
import '../controllers/book_detail_controller.dart';
import '../../cart/views/payment_screen.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {

  // 좋아요 핸들러
  void _handleLike() async {
    try {
      await ref.read(likeStatusProvider(widget.book.id).notifier).toggleLike(widget.book);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    }
  }

  // 장바구니 핸들러
  void _handleAddToCart() async {
    try {
      await ref.read(cartControllerProvider).addToCart(widget.book);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("장바구니에 담겼습니다.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###", "ko_KR");
    final book = widget.book;

    // Riverpod 상태 구독
    final isLikedAsync = ref.watch(likeStatusProvider(book.id));
    final isPurchasedAsync = ref.watch(purchaseStatusProvider(book.id));
    final reviewsAsync = ref.watch(bookReviewsProvider(book.id));

    final bool isLiked = isLikedAsync.value ?? false;
    final bool isPurchased = isPurchasedAsync.value ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. 배경 레이어
          // ---------------------------------------------------------
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
                    const Color(0xFF999999).withOpacity(0.6),
                    const Color(0xFF222222).withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 206,
            left: 1,
            right: 1,
            height: 434,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
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
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFEA4335), shape: BoxShape.circle),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

// 책 표지
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
                              blurRadius: 2),
                        ],
                        // 여기서 image 속성은 통째로 지워줍니다!
                      ),
                      // 🌟 대신 child 안으로 CustomNetworkImage를 쏙 넣습니다.
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CustomNetworkImage(
                          imageUrl: book.imageUrl,
                          width: 165.0,
                          height: 250.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 책 기본 정보
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF222222),
                              letterSpacing: -0.025),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              color: Color(0xFF777777),
                              letterSpacing: -0.05),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFBBC05), size: 16),
                            const SizedBox(width: 4),
                            Text(book.rating,
                                style: const TextStyle(
                                    color: Color(0xFFFBBC05),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Text("(${book.reviewCount})",
                                style: const TextStyle(color: Color(0xFF767676), fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (book.discountRate != null && book.discountRate! > 0)
                              Text(
                                "${book.discountRate}%",
                                style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEA4335)),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              "${currencyFormat.format(book.discountedPrice)}원",
                              style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF222222)),
                            ),
                            const SizedBox(width: 8),
                            if (book.discountRate != null && book.discountRate! > 0)
                              Text(
                                "${currencyFormat.format(book.price)}원",
                                style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    color: Color(0xFF767676)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 줄거리 & 태그
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("줄거리",
                            style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222))),
                        const SizedBox(height: 10),
                        Text(
                          book.description.isNotEmpty ? book.description : "줄거리 정보가 없습니다.",
                          style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFF767676)),
                        ),
                        const SizedBox(height: 20),
                        if (book.tags.isNotEmpty)
                          Wrap(
                            spacing: 10,
                            children: book.tags.map((tag) => Text(
                              tag.startsWith('#') ? tag : "#$tag",
                              style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0088DD)),
                            )).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 리뷰 영역
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("리뷰",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                        GestureDetector(
                          onTap: _showAllReviewsBottomSheet,
                          child: const Text("더보기",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF767676))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 가로 스크롤 리뷰 리스트 (Riverpod 적용)
                  SizedBox(
                    height: 150,
                    child: reviewsAsync.when(
                      data: (snapshot) {
                        if (snapshot.docs.isEmpty) {
                          return _buildEmptyReview();
                        }
                        final reviews = snapshot.docs;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final reviewData = reviews[index].data() as Map<String, dynamic>;
                            return _buildReviewCardFromData(reviewData);
                          },
                        );
                      },
                      error: (_, __) => const Center(child: Text("리뷰를 불러오는 중 오류가 발생했습니다.")),
                      loading: () => const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 3. 하단 구매 바
          // ---------------------------------------------------------
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.only(top: 18, left: 24, right: 24, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  // 좋아요 버튼
                  InkWell(
                    onTap: _handleLike,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: const Color(0xFFED7777),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        const Text("좋아요",
                            style: TextStyle(fontSize: 10, color: Color(0xFF222222))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // 장바구니 버튼
                  InkWell(
                    onTap: _handleAddToCart,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_cart_outlined, color: Color(0xFF222222), size: 24),
                        SizedBox(height: 4),
                        Text("장바구니",
                            style: TextStyle(fontSize: 10, color: Color(0xFF222222))),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // 구매하기 버튼
                  GestureDetector(
                    onTap: isPurchased
                        ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("이미 소장하고 있는 도서입니다.")));
                    }
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            items: [
                              {
                                'id': book.id,
                                'title': book.title,
                                'author': book.author,
                                'imageUrl': book.imageUrl,
                                'price': book.discountedPrice
                              }
                            ],
                            totalPrice: book.discountedPrice,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 219,
                      height: 52,
                      decoration: BoxDecoration(
                          color: isPurchased ? const Color(0xFFDBDBDB) : const Color(0xFFD45858),
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Text(isPurchased ? "구매완료" : "구매하기",
                            style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
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

  // 리뷰 없음 위젯
  Widget _buildEmptyReview() {
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

  // 리뷰 데이터 처리 헬퍼
  Widget _buildReviewCardFromData(Map<String, dynamic> data) {
    double rating = double.tryParse(data['rating'].toString()) ?? 5.0;
    Timestamp? createdAt = data['createdAt'] as Timestamp?;
    return _buildReviewCard(
      data['userName'] ?? '익명',
      data['content'] ?? '',
      rating,
      createdAt,
    );
  }

  // 리뷰 카드 위젯
  Widget _buildReviewCard(String user, String content, double rating, Timestamp? timestamp) {
    String dateStr = "날짜 없음";
    if (timestamp != null) {
      dateStr = DateFormat('yyyy. MM. dd').format(timestamp.toDate());
    }

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
            children: List.generate(5, (index) {
              return Icon(index < rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFBBC05), size: 14);
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(user, style: const TextStyle(fontSize: 12, color: Color(0xFF767676))),
              const SizedBox(width: 8),
              Container(width: 1, height: 10, color: const Color(0xFFDDDDDD)),
              const SizedBox(width: 8),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF767676))),
            ],
          ),
          const SizedBox(height: 10),
          Text(content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF222222), height: 1.4)),
        ],
      ),
    );
  }

  // 바텀 시트로 전체 리뷰 보여주기 (Riverpod 적용)
  void _showAllReviewsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer( // 내부에서 Provider 사용을 위해 Consumer 사용
          builder: (context, ref, _) {
            final reviewsAsync = ref.watch(bookReviewsProvider(widget.book.id));

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("전체 리뷰",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: reviewsAsync.when(
                      data: (snapshot) {
                        if (snapshot.docs.isEmpty) {
                          return const Center(child: Text("리뷰가 없습니다."));
                        }
                        final docs = snapshot.docs;
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return _buildReviewCardFromDataVertical(data);
                          },
                        );
                      },
                      error: (_, __) => const Center(child: Text("리뷰를 불러오지 못했습니다.")),
                      loading: () => const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 세로 리스트용 아이템 데이터 헬퍼
  Widget _buildReviewCardFromDataVertical(Map<String, dynamic> data) {
    double rating = double.tryParse(data['rating'].toString()) ?? 5.0;
    Timestamp? createdAt = data['createdAt'] as Timestamp?;
    return _buildVerticalReviewItem(
      data['userName'] ?? '익명',
      data['content'] ?? '',
      rating,
      createdAt,
    );
  }

  // 세로 리스트용 아이템 위젯
  Widget _buildVerticalReviewItem(String user, String content, double rating, Timestamp? timestamp) {
    String dateStr = timestamp != null
        ? DateFormat('yyyy. MM. dd').format(timestamp.toDate())
        : "";

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFBBC05), size: 16)),
              ),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}