import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/payment_repository.dart';

final paymentControllerProvider = Provider.autoDispose((ref) {
  return PaymentController(ref);
});

class PaymentController {
  final Ref ref;
  PaymentController(this.ref);

  Future<void> processPayment(List<Map<String, dynamic>> items) async {
    await ref.read(paymentRepositoryProvider).purchaseBooks(items);
  }
}