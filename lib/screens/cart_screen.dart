import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart'; // 결제 화면 import

// 로컬에서 UI 상태 관리를 위해 확장한 클래스
class CartItemModel {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final int originalPrice;
  final int discountedPrice;

  CartItemModel({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
  });

  factory CartItemModel.fromMap(String id, Map<String, dynamic> map) {
    return CartItemModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      originalPrice: map['originalPrice'] ?? 0,
      discountedPrice: map['discountedPrice'] ?? 0,
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // 선택된 항목의 ID를 저장하는 Set
  final Set<String> _selectedItemIds = {};

  // 전체 선택 여부
  bool _isAllSelected = true;

  // 합계 계산
  int _totalProductPrice = 0;
  int _totalDiscountPrice = 0;
  int _totalPaymentPrice = 0;

  List<CartItemModel> _loadedItems = [];

  // 숫자를 원화 형식으로 변환
  String _formatPrice(int price) {
    return NumberFormat('###,###,###,###원').format(price);
  }

  // 계산 로직 업데이트
  void _calculateTotals() {
    int product = 0;
    int payment = 0;

    for (var item in _loadedItems) {
      if (_selectedItemIds.contains(item.id)) {
        product += item.originalPrice;
        payment += item.discountedPrice;
      }
    }

    setState(() {
      _totalProductPrice = product;
      _totalPaymentPrice = payment;
      _totalDiscountPrice = product - payment;
    });
  }

  // DB에서 항목 삭제
  void _deleteItem(String docId) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cart')
          .doc(docId)
          .delete();

      _selectedItemIds.remove(docId); // 선택 목록에서도 제거
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('cart')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          // 데이터가 로드되면 모델 리스트로 변환
          _loadedItems = docs.map((doc) {
            return CartItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          // 초기 진입 시(혹은 아이템 추가 시) 선택 로직:
          // 기존에 선택된 정보가 없으면 모두 선택 상태로 초기화할 수도 있음
          // 하지만 여기서는 _selectedItemIds에 없는 새로운 아이템이 들어오면 기본적으로 선택되도록 처리
          for(var item in _loadedItems) {
            // 만약 _isAllSelected가 true 상태라면 새로 들어온 것도 자동 선택
            if (_isAllSelected && !_selectedItemIds.contains(item.id)) {
              _selectedItemIds.add(item.id);
            }
          }

          // 화면 렌더링 시점마다 계산 업데이트 (Future.microtask로 에러 방지)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 무한 루프 방지를 위해 값이 다를 때만 setState 호출해야 하지만,
            // 간단하게는 calculate를 여기서 직접 호출하지 않고,
            // build 내에서 변수만 계산해서 보여주는 방식이 더 안전함.
            // 여기서는 편의상 보여주는 값 변수만 갱신하겠습니다.
            int product = 0;
            int payment = 0;
            for (var item in _loadedItems) {
              if (_selectedItemIds.contains(item.id)) {
                product += item.originalPrice;
                payment += item.discountedPrice;
              }
            }
            if(_totalPaymentPrice != payment) {
              setState(() {
                _totalProductPrice = product;
                _totalPaymentPrice = payment;
                _totalDiscountPrice = product - payment;
              });
            }
          });

          if (_loadedItems.isEmpty) {
            return const Center(child: Text("장바구니가 비어있습니다."));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildSelectAll(),
                    ..._loadedItems.map((item) => _buildCartItem(item)).toList(),
                    Container(height: 8, color: const Color(0xFFF5F5F5)),
                  ],
                ),
              ),
              _buildPriceSummary(),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _totalPaymentPrice == 0 ? null : () {
            // 선택된 아이템만 필터링하여 결제 페이지로 전달
            final selectedItems = _loadedItems
                .where((item) => _selectedItemIds.contains(item.id))
                .map((item) => {
              'title': item.title,
              'author': item.author,
              'imageUrl': item.imageUrl,
              'price': item.discountedPrice
            })
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  items: selectedItems,
                  totalPrice: _totalPaymentPrice,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: Text(
            '${_formatPrice(_totalPaymentPrice)} 구매하기 (${_selectedItemIds.length}개)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

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
                if (_isAllSelected) {
                  _selectedItemIds.addAll(_loadedItems.map((e) => e.id));
                } else {
                  _selectedItemIds.clear();
                }
              });
            },
            activeColor: Colors.redAccent,
          ),
          const Text('전체 선택'),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    final isSelected = _selectedItemIds.contains(item.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedItemIds.add(item.id);
                } else {
                  _selectedItemIds.remove(item.id);
                  _isAllSelected = false; // 하나라도 해제하면 전체 선택 해제
                }
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
            onPressed: () => _deleteItem(item.id),
          ),
        ],
      ),
    );
  }

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