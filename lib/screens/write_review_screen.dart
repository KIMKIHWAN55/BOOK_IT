import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookit_app/models/book_model.dart';

class WriteReviewScreen extends StatefulWidget {
  final BookModel book;
  const WriteReviewScreen({super.key, required this.book});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _contentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("내용을 입력해주세요.")));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("로그인 정보가 없습니다.");

      final bookRef = FirebaseFirestore.instance.collection('books').doc(widget.book.id);

      // 1. Firestore 트랜잭션 사용 (데이터 무결성 보장)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot bookSnapshot = await transaction.get(bookRef);

        if (!bookSnapshot.exists) {
          throw Exception("책 데이터가 존재하지 않습니다.");
        }

        // 2. 현재 책의 평점과 리뷰 수 가져오기
        Map<String, dynamic> data = bookSnapshot.data() as Map<String, dynamic>;

        // 기존 평점과 리뷰 수를 숫자로 변환 (없으면 0.0)
        double currentRating = double.tryParse(data['rating']?.toString() ?? '0.0') ?? 0.0;
        int currentReviewCount = int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0;

        // 3. 새로운 평균 평점 계산 공식
        // (기존총점 + 내점수) / (기존개수 + 1)
        double newRating = ((currentRating * currentReviewCount) + _rating) / (currentReviewCount + 1);

        // 소수점 한 자리까지만 저장 (예: 4.5)
        String newRatingStr = newRating.toStringAsFixed(1);
        String newCountStr = (currentReviewCount + 1).toString();

        // 4. 리뷰 서브컬렉션에 내 리뷰 추가
        final reviewRef = bookRef.collection('reviews').doc(); // 문서 ID 자동 생성
        transaction.set(reviewRef, {
          'uid': user.uid,
          'userName': user.displayName ?? '익명',
          'content': _contentController.text,
          'rating': _rating,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 5. 책 문서에 새로운 평점과 리뷰 수 업데이트
        transaction.update(bookRef, {
          'rating': newRatingStr,
          'reviewCount': newCountStr,
        });
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("리뷰가 등록되었습니다.")));
      }

    } catch (e) {
      print("리뷰 등록 오류: $e");
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("리뷰 작성하기")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "이 책에 대한 솔직한 리뷰를 남겨주세요.",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD45858)),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("등록하기", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}