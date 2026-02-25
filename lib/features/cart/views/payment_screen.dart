import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/payment_controller.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> items;
  final int totalPrice;

  const PaymentScreen({
    super.key,
    required this.items,
    required this.totalPrice,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isLoading = false;

  // 결제 처리 핸들러
  void _handlePayment() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      //  Controller를 통해 결제 요청
      await ref.read(paymentControllerProvider).processPayment(widget.items);

      //  결제 완료
      if (mounted) {
        final formatCurrency = NumberFormat("#,###", "ko_KR");
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("결제 완료"),
            content: Text("총 ${formatCurrency.format(widget.totalPrice)}원이 결제되었습니다.\n내 서재에 책이 추가되었습니다."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
            ...widget.items.map((item) => Container(
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
          // 로딩 중일 때는 null을 주어 버튼을 비활성화 시킴
          onPressed: _isLoading ? null : _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD45858),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: const Color(0xFFD45858).withOpacity(0.5),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : Text(
            "${formatCurrency.format(widget.totalPrice)}원 결제하기",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}