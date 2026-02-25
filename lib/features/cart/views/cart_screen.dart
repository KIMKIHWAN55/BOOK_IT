import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/cart_item_model.dart';
import '../controllers/cart_controller.dart';
import 'payment_screen.dart';
import '../../../shared/widgets/custom_network_image.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final Set<String> _selectedItemIds = {};
  bool _isAllSelected = true;

  String _formatPrice(int price) {
    return NumberFormat('###,###,###,###원').format(price);
  }

  // 항목 삭제
  void _deleteItem(String docId) async {
    try {
      await ref.read(cartActionControllerProvider).deleteItem(docId);
      setState(() {
        _selectedItemIds.remove(docId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("삭제 실패: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

    final cartAsync = ref.watch(cartListProvider);

    List<CartItemModel> loadedItems = [];
    int totalProductPrice = 0;
    int totalPaymentPrice = 0;

    cartAsync.whenData((items) {
      loadedItems = items;
      if (_isAllSelected) {
        _selectedItemIds.addAll(items.map((e) => e.id));
      }

      // 동적 가격 계산
      for (var item in items) {
        if (_selectedItemIds.contains(item.id)) {
          totalProductPrice += item.originalPrice;
          totalPaymentPrice += item.discountedPrice;
        }
      }
    });

    int totalDiscountPrice = totalProductPrice - totalPaymentPrice;

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
      body: cartAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("장바구니가 비어있습니다."));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildSelectAll(items),
                    ...items.map((item) => _buildCartItem(item, items.length)).toList(),
                    Container(height: 8, color: const Color(0xFFF5F5F5)),
                  ],
                ),
              ),
              _buildPriceSummary(totalProductPrice, totalDiscountPrice, totalPaymentPrice),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("오류가 발생했습니다: $e")),
      ),
      bottomNavigationBar: loadedItems.isEmpty
          ? null
          : _buildBottomButton(loadedItems, totalPaymentPrice),
    );
  }

  Widget _buildSelectAll(List<CartItemModel> items) {
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
                  _selectedItemIds.addAll(items.map((e) => e.id));
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

  Widget _buildCartItem(CartItemModel item, int totalCount) {
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
                  // 개별적으로 모두 선택되면 전체 선택 체크 활성화
                  if (_selectedItemIds.length == totalCount) {
                    _isAllSelected = true;
                  }
                } else {
                  _selectedItemIds.remove(item.id);
                  _isAllSelected = false;
                }
              });
            },
            activeColor: Colors.redAccent,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CustomNetworkImage(
              imageUrl: item.imageUrl,
              width: 80,
              height: 100,
            ),
          ),
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

  Widget _buildPriceSummary(int productPrice, int discountPrice, int paymentPrice) {
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
              Text(_formatPrice(productPrice)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('할인 금액', style: TextStyle(color: Colors.grey)),
              Text('-${_formatPrice(discountPrice)}'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총 구매 금액', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_formatPrice(paymentPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(List<CartItemModel> items, int totalPaymentPrice) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: totalPaymentPrice == 0 ? null : () {
          final selectedItems = items
              .where((item) => _selectedItemIds.contains(item.id))
              .map((item) => {
            'id': item.id,
            'title': item.title,
            'author': item.author,
            'imageUrl': item.imageUrl,
            'price': item.discountedPrice
          }).toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                items: selectedItems,
                totalPrice: totalPaymentPrice,
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
          '${_formatPrice(totalPaymentPrice)} 구매하기 (${_selectedItemIds.length}개)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}