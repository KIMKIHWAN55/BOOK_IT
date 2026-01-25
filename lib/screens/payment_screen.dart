import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int totalPrice;

  const PaymentScreen({
    super.key,
    required this.items,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat("#,###", "ko_KR");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("결제하기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("주문 상품", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // 주문 목록 리스트
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(item['imageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(item['author'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("${formatCurrency.format(item['price'])}원", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            )).toList(),

            const Divider(height: 40, thickness: 1),

            const Text("결제 수단", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.credit_card, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("신용/체크카드", style: TextStyle(fontSize: 16)),
                  Spacer(),
                  Icon(Icons.check_circle, color: Colors.redAccent),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            // 1. 로그인 유저 확인
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
              return;
            }

            // 2. Firestore에 구매 정보 저장 (users -> uid -> purchased_books)
            final batch = FirebaseFirestore.instance.batch();

            for (var item in items) {
              // item에 'id'가 포함되어 있어야 합니다. (장바구니나 상세페이지에서 넘겨줄 때 id 포함 필수)
              final bookId = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

              final docRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('purchased_books')
                  .doc(bookId);

              batch.set(docRef, {
                'id': bookId,
                'title': item['title'],
                'author': item['author'],
                'imageUrl': item['imageUrl'],
                'price': item['price'],
                'purchasedAt': FieldValue.serverTimestamp(), // 구매 시간
                'currentPage': 0, // 👈 내 서재 독서 기록용 (초기값 0)
              });
            }

            await batch.commit(); // 일괄 저장 실행

            // 3. 결제 완료 팝업 (기존 코드 유지)
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("결제 완료"),
                  content: Text("총 ${formatCurrency.format(totalPrice)}원이 결제되었습니다.\n내 서재에 책이 추가되었습니다."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // 다이얼로그 닫기
                        Navigator.popUntil(context, (route) => route.isFirst); // 홈으로 이동
                      },
                      child: const Text("확인"),
                    ),
                  ],
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD45858),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            "${formatCurrency.format(totalPrice)}원 결제하기",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}