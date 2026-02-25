import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../repositories/cart_repository.dart';

// 장바구니 목록 스트림
final cartListProvider = StreamProvider.autoDispose<List<CartItemModel>>((ref) {
  final repository = ref.read(cartRepositoryProvider);
  return repository.getCartStream().map((snapshot) {
    return snapshot.docs.map((doc) =>
        CartItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)
    ).toList();
  });
});

// 장바구니 액션 컨트롤러
final cartActionControllerProvider = Provider.autoDispose((ref) {
  return CartActionController(ref);
});

class CartActionController {
  final Ref ref;
  CartActionController(this.ref);

  Future<void> deleteItem(String docId) async {
    await ref.read(cartRepositoryProvider).deleteCartItem(docId);
  }
}