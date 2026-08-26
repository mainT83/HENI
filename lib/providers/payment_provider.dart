import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_repository.dart';
import 'supabase_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(supabaseClientProvider));
});
