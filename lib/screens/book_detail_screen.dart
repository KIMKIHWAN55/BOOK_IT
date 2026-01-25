import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Auth 추가
import '../models/book_model.dart';
import 'payment_screen.dart'; // 결제 스크린 import (새로 생성 필요)

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool isLiked = false; // 좋아요 상태
  bool isPurchased = false;
  final user = FirebaseAuth.instance.currentUser; // 현재 로그인한 유저

  @override
  void initState() {
    super.initState();
    _checkIfLiked(); // 초기 좋아요 상태 확인
    _checkIfPurchased();
  }

  // 좋아요 상태 확인
  void _checkIfLiked() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('liked_books')
        .doc(widget.book.id)
        .get();
    if (mounted) {
      setState(() {
        isLiked = doc.exists;
      });
    }
  }

  void _checkIfPurchased() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('purchased_books')
          .doc(widget.book.id)
          .get();

      if (mounted) {
        setState(() {
          isPurchased = doc.exists; // 문서가 존재하면 true (이미 구매함)
        });
      }
    } catch (e) {
      print("구매 여부 확인 중 오류: $e");
    }
  }

  // 좋아요 토글 기능
  void _toggleLike() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('liked_books')
        .doc(widget.book.id);

    if (isLiked) {
      await ref.delete();
      if (mounted) setState(() => isLiked = false);
    } else {
      await ref.set({
        'title': widget.book.title,
        'author': widget.book.author,
        'imageUrl': widget.book.imageUrl,
        'likedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => isLiked = true);
    }
  }

  // 장바구니 담기 기능
  void _addToCart() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    // 장바구니에 저장할 데이터 구성
    // BookModel의 toMap을 사용하거나 직접 구성
    // 여기서는 장바구니 화면에서 필요한 필드 위주로 저장
    final cartData = {
      'id': widget.book.id,
      'title': widget.book.title,
      'author': widget.book.author,
      'imageUrl': widget.book.imageUrl,
      'originalPrice': widget.book.price,
      'discountedPrice': widget.book.discountedPrice,
      'addedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(widget.book.id)
        .set(cartData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("장바구니에 담겼습니다.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화폐 포맷
    final currencyFormat = NumberFormat("#,###", "ko_KR");
    final book = widget.book;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. 배경 레이어 (기존 코드 유지)
          // ---------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
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
            top: 206,
            left: 1,
            right: 1,
            height: 434,
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
          // 2. 메인 컨텐츠 (기존 코드 유지)
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
                          child: const Icon(Icons.arrow_back_ios, color: Colors
                              .white),
                        ),
                        Stack(
                          children: [
                            const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 28),
                            Positioned(
                              right: 2, top: 2,
                              child: Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFEA4335),
                                    shape: BoxShape.circle),
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
                      width: 165, height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 2),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(book.imageUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
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
                          style: const TextStyle(fontFamily: 'Pretendard',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF222222),
                              letterSpacing: -0.025),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: const TextStyle(fontFamily: 'Pretendard',
                              fontSize: 14,
                              color: Color(0xFF777777),
                              letterSpacing: -0.05),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFBBC05),
                                size: 16),
                            const SizedBox(width: 4),
                            Text(book.rating, style: const TextStyle(
                                color: Color(0xFFFBBC05),
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Text("(${book.reviewCount})",
                                style: const TextStyle(
                                    color: Color(0xFF767676), fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (book.discountRate != null && book
                                .discountRate! > 0)
                              Text(
                                "${book.discountRate}%",
                                style: const TextStyle(fontFamily: 'Pretendard',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEA4335)),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              "${currencyFormat.format(book.discountedPrice)}원",
                              style: const TextStyle(fontFamily: 'Pretendard',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF222222)),
                            ),
                            const SizedBox(width: 8),
                            if (book.discountRate != null && book
                                .discountRate! > 0)
                              Text(
                                "${currencyFormat.format(book.price)}원",
                                style: const TextStyle(fontFamily: 'Pretendard',
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

                  // 줄거리 & 태그 (기존 유지)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("줄거리", style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222))),
                        const SizedBox(height: 10),
                        Text(
                          book.description.isNotEmpty
                              ? book.description
                              : "줄거리 정보가 없습니다.",
                          style: const TextStyle(fontFamily: 'Pretendard',
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFF767676)),
                        ),
                        const SizedBox(height: 20),
                        if (book.tags.isNotEmpty)
                          Wrap(
                            spacing: 10,
                            children: book.tags.map((tag) =>
                                Text(
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

                  // 리뷰 영역 (기존 유지)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("리뷰", style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222))),
                        Text("더보기", style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF767676))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 150,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('books')
                          .doc(book.id)
                          .collection('reviews')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFEEEEEE)),
                            ),
                            child: const Center(
                              child: Text(
                                "아직 등록된 리뷰가 없습니다.",
                                style: TextStyle(
                                    color: Color(0xFF767676), fontSize: 14),
                              ),
                            ),
                          );
                        }
                        final reviews = snapshot.data!.docs;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final reviewData = reviews[index].data() as Map<
                                String,
                                dynamic>;
                            double rating = double.tryParse(
                                reviewData['rating'].toString()) ?? 5.0;
                            Timestamp? createdAt = reviewData['createdAt'] as Timestamp?;
                            return _buildReviewCard(
                                reviewData['userName'] ?? '익명',
                                reviewData['content'] ?? '',
                                rating,
                                createdAt
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
          // 3. 하단 구매 바 (기능 구현됨)
          // ---------------------------------------------------------
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.only(
                  top: 18, left: 24, right: 24, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  // 좋아요 버튼
                  InkWell(
                    onTap: _toggleLike,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: const Color(0xFFED7777),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                            "좋아요", style: TextStyle(fontSize: 10, color: Color(
                            0xFF222222))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // 장바구니 버튼
                  InkWell(
                    onTap: _addToCart,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_cart_outlined,
                            color: Color(0xFF222222), size: 24),
                        SizedBox(height: 4),
                        Text(
                            "장바구니", style: TextStyle(fontSize: 10, color: Color(
                            0xFF222222))),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // 구매하기 버튼 -> 결제 페이지로 이동
                  GestureDetector(
                    // 👇 이미 구매했으면 클릭 안 되게 처리 (null)
                    onTap: isPurchased
                        ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("이미 소장하고 있는 도서입니다."))
                      );
                    }
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PaymentScreen(
                                items: [{
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
                      width: 219, height: 52,
                      decoration: BoxDecoration(
                        // 👇 구매했으면 회색, 아니면 원래 색(빨강)
                          color: isPurchased
                              ? const Color(0xFFDBDBDB)
                              : const Color(0xFFD45858),
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: Center(
                        child: Text(
                          // 👇 텍스트도 변경
                            isPurchased ? "구매완료" : "구매하기",
                            style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white
                            )
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

  // 리뷰 카드 위젯 (기존 유지)
  Widget _buildReviewCard(String user, String content, double rating,
      Timestamp? timestamp) {
    // 날짜 변환
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
        crossAxisAlignment: CrossAxisAlignment.start, // 👈 1. 왼쪽 정렬 추가
        children: [
          Row(
            // 별점 표시
            children: List.generate(5, (index) {
              return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFBBC05),
                  size: 14
              );
            }),
          ),
          const SizedBox(height: 8), // 👈 2. 별점과 이름 사이 간격 추가
          Row(
            children: [
              Text(user, style: const TextStyle(
                  fontSize: 12, color: Color(0xFF767676))),
              const SizedBox(width: 8),
              Container(width: 1, height: 10, color: const Color(0xFFDDDDDD)),
              const SizedBox(width: 8),
              Text(dateStr, style: const TextStyle(
                  fontSize: 12, color: Color(0xFF767676))),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF222222), height: 1.4)),
        ],
      ),
    );
  }
}