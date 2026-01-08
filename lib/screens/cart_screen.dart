import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 숫자 포맷팅을 위해 intl 패키지 사용

// 장바구니 아이템의 데이터 구조를 정의하는 클래스
class CartItem {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final int originalPrice;
  final int discountedPrice;
  bool isSelected;

  CartItem({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
    this.isSelected = true,
  });
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // 임시 장바구니 데이터 (나중에는 백엔드에서 받아와야 합니다)
  final List<CartItem> _cartItems = [
    CartItem(
      id: '1',
      title: 'Paradox',
      author: '호베르투 카를로스',
      imageUrl: 'https://i.ibb.co/3sHHDq2/paradox-cover.jpg',
      originalPrice: 13000,
      discountedPrice: 10400,
    ),
    CartItem(
      id: '2',
      title: '1퍼센트 부자들의 법칙',
      author: '김민규',
      imageUrl: 'https://i.ibb.co/4222L1m/book4.jpg',
      originalPrice: 11500,
      discountedPrice: 11500,
    ),
    CartItem(
      id: '3',
      title: '그 시절 내가 좋아했던',
      author: '김민수',
      imageUrl: 'https://i.ibb.co/b6yFp7G/book1.jpg',
      originalPrice: 12000,
      discountedPrice: 10000,
    ),
  ];

  bool _isAllSelected = true;
  int _totalProductPrice = 0;
  int _totalDiscountPrice = 0;
  int _totalPaymentPrice = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotals(); // 화면이 시작될 때 총액을 계산
  }

  // 금액을 계산하는 함수
  void _calculateTotals() {
    _totalProductPrice = 0;
    _totalDiscountPrice = 0;
    _totalPaymentPrice = 0;

    for (var item in _cartItems) {
      if (item.isSelected) {
        _totalProductPrice += item.originalPrice;
        _totalDiscountPrice += item.originalPrice - item.discountedPrice;
        _totalPaymentPrice += item.discountedPrice;
      }
    }

    // 모든 아이템이 선택되었는지 확인하여 '전체 선택' 체크박스 상태 업데이트
    _isAllSelected = _cartItems.every((item) => item.isSelected);

    setState(() {}); // 화면 갱신
  }

  // 숫자를 원화(₩) 형식으로 포맷팅하는 함수
  String _formatPrice(int price) {
    var format = NumberFormat('###,###,###,###원');
    return format.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('장바구니', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 책 목록이 있는 상단 영역
          Expanded(
            child: ListView(
              children: [
                _buildSelectAll(), // 전체 선택 체크박스
                ..._cartItems.map((item) => _buildCartItem(item)).toList(), // 장바구니 아이템 목록
                Container(height: 8, color: const Color(0xFFF5F5F5)), // 회색 구분선
              ],
            ),
          ),
          // 구매 금액 정보가 있는 하단 영역
          _buildPriceSummary(),
        ],
      ),
      // 구매하기 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '${_formatPrice(_totalPaymentPrice)} 구매하기 (${_cartItems.where((i) => i.isSelected).length}개)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // 전체 선택 UI
  Widget _buildSelectAll() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: _isAllSelected,
            onChanged: (value) {
              setState(() {
                _isAllSelected = value ?? false;
                for (var item in _cartItems) {
                  item.isSelected = _isAllSelected;
                }
                _calculateTotals();
              });
            },
            activeColor: Colors.redAccent,
          ),
          const Text('전체 선택'),
        ],
      ),
    );
  }

  // 개별 장바구니 아이템 UI
  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Checkbox(
            value: item.isSelected,
            onChanged: (value) {
              setState(() {
                item.isSelected = value ?? false;
                _calculateTotals();
              });
            },
            activeColor: Colors.redAccent,
          ),
          Image.network(item.imageUrl, width: 80, height: 100, fit: BoxFit.cover),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(item.author, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                if (item.originalPrice != item.discountedPrice)
                  Text(
                    _formatPrice(item.originalPrice),
                    style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough),
                  ),
                Text(_formatPrice(item.discountedPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _cartItems.remove(item);
                _calculateTotals();
              });
            },
          ),
        ],
      ),
    );
  }

  // 구매 금액 요약 UI
  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('구매 금액', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('상품 금액', style: TextStyle(color: Colors.grey)),
              Text(_formatPrice(_totalProductPrice)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('할인 금액', style: TextStyle(color: Colors.grey)),
              Text('-${_formatPrice(_totalDiscountPrice)}'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총 구매 금액', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_formatPrice(_totalPaymentPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }
}